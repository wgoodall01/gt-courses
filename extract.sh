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
	id text not null primary key,
	term text not null,
	term_description text not null,
	crn text not null,
	number text not null,
	subject text not null,
	subject_description text not null,
	section text not null,
	campus text not null,
	schedule_type text not null,
	course_title not null,
	credit_hours integer not null,
	max_enrollment integer not null,
	enrollment integer not null,
	seats_available integer not null,
	waitlist_capacity integer not null,
	waitlist_count integer not null,
	waitlist_available integer not null,
	open boolean not null,
	attributes text,
	raw json not null
);

create index ix_sections_nums on sections(subject, number, section);

create table faculty (
	id text not null primary key,
	name text not null,
	email text not null
);

create table course_faculty (
	course_id text not null references sections(id),
	faculty_id text not null references faculty(id),
	primary key (course_id, faculty_id)
);

create table requirements (
	program text,
	subject text,
	number text,
	why text
);

create index ix_requirements on requirements(subject, number);

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
			([.sectionAttributes[].code] | join(",")),
			tojson
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

echo '[+] Importing requirements...'
sqlite3 courses.sqlite3 ".import --csv '../course_requirements.csv' requirements"

echo "[+] Check validity..."
sqlite3 courses.sqlite3 <<EOF
pragma foreign_keys = ON;
pragma foreign_key_check;
EOF

echo '[+] Tidy up...'
sqlite3 courses.sqlite3 <<EOF
update sections set attributes = null where attributes = '';
EOF

echo '[+] Create views...'
sqlite3 courses.sqlite3 <../views.sql

echo '[+] Vaccuum...'
sqlite3 courses.sqlite3 'vacuum;'
