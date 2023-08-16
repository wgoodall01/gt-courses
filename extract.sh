#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR/_data"

echo '[+] Merging fetched data...'
cat courses.*.json | jq '.data[]' > all_courses.json

echo '[+] Creating database...'

sqlite3 courses.sqlite3 <<EOF
pragma foreign_keys = ON;

create table sections (
	id text,
	term text,
	term_description text,
	crn text,
	number text,
	subject text,
	subject_description text,
	section text,
	campus text,
	schedule_type text,
	course_title,
	credit_hours integer,
	max_enrollment integer,
	enrollment integer,
	seats_available integer,
	waitlist_capacity integer,
	waitlist_count integer,
	waitlist_available integer,
	open boolean,
	attributes text
);

create index ix_sections_nums on sections(subject, number, section);

create table faculty (
	banner_id text not null primary key,
	name text not null,
	email text not null
);

create table course_faculty (
	course_id text not null,
	faculty_id text not null,
	primary key (course_id, faculty_id)
);

EOF

echo '[+] Importing sections...'
jq -r <all_courses.json \
	'
		[
			.id,
			.term,
			.termDesc,
			.courseReferenceNumber,
			.courseNumber,
			.subject,
			.subjectDescription,
			.sequenceNumber,
			.campusDescription,
			.scheduleTypeDescription,
			.courseTitle,
			.creditHours,
			.maximumEnrollment,
			.enrollment,
			.seatsAvailable,
			.waitCapacity,
			.waitCount,
			.waitAvailable,
			.openSection,
			([.sectionAttributes[].code] | join(","))
		] | @csv
	'\
	| sqlite3 courses.sqlite3 ".import --csv '|cat -' sections"

echo '[+] Importing faculty...'
jq -r <all_courses.json \
	'
		.faculty[] 
		| [.bannerId, .displayName, .emailAddress]
		| @csv
	' \
	| sort \
	| uniq \
 	| sqlite3 courses.sqlite3 ".import --csv '|cat -' faculty"

echo '[+] Importing faculty for courses...'
jq -r <all_courses.json \
	'
		.id as $course_id
		| .faculty[]
		| [$course_id, .bannerId]
		| @csv
	'\
	| sqlite3 courses.sqlite3 ".import --csv '|cat -' course_faculty"

echo '[+] Importing online-only sections from Qualtrics form...'
sqlite3 courses.sqlite3 \
	'create table tmp_online_sections(subject text, number text, section text, course_title text);'
jq -r <../permit_sections.json  \
	'
	.[] 
	| select(test("AO|REMOTE")) 
	| split(" ") 
	| [.[0], .[1], .[2], (.[3:-2] | join(" "))]
	| @csv'\
	| sqlite3 courses.sqlite3 ".import --csv '|cat -' tmp_online_sections"
echo "    Merging in..."
sqlite3 courses.sqlite3 \
	'
	insert into sections (subject, number, section, course_title) 
	select subject, number, section, course_title from tmp_online_sections;
	drop table tmp_online_sections;
	'


echo "[+] Check validity..."
sqlite3 courses.sqlite3 <<EOF
pragma foreign_keys = ON;
pragma foreign_key_check;
EOF

echo '[+] Tidy up...'
sqlite3 courses.sqlite3 <<EOF
update sections set attributes = null where attributes = '';
EOF
