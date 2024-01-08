#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rm -rf "$DIR/_data"
mkdir "$DIR/_data"
cd "$DIR/_data"

echo '[+] Opening a session'
rm -f cookies.txt && touch cookies.txt
curl \
	-L \
	--silent \
	--cookie-jar cookies.txt \
	-o /dev/null \
	'https://registration.banner.gatech.edu/StudentRegistrationSsb/ssb/classSearch/classSearch'

urlencode() {
	string="$1"
	encoded_string=$(printf '%s' "$string" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
	echo "$encoded_string"
}

echo '[+] Fetching term list'
curl 'https://registration.banner.gatech.edu/StudentRegistrationSsb/ssb/classSearch/getTerms?searchTerm=&offset=1&max=10&_=1692145375364' \
	--cookie cookies.txt \
	--silent \
	-H 'Accept: application/json, text/javascript, */*; q=0.01' \
	-H 'Connection: keep-alive' \
	-H 'Pragma: no-cache' \
	-H 'Cache-Control: no-cache' \
	| jq -r '.[] | "    \(.code)    \(.description)"'

term="202402"
echo "    Using term: ${term}"

echo '[+] POST search (initialize session)'
curl 'https://registration.banner.gatech.edu/StudentRegistrationSsb/ssb/term/search?mode=search' \
	--cookie cookies.txt \
	--silent \
	-H 'Accept: */*' \
	-H 'Accept-Language: en-US,en;q=0.9' \
	-H 'Connection: keep-alive' \
	-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
	--data-raw "term=${term}&studyPath=&studyPathText=&startDatepicker=&endDatepicker=" \
	--compressed \
	-o /dev/null

echo '[+] Fetching data'

offset=0
page_size=500
total_records="unknown"
total_retrieved=0

while : ; do
	file="courses.ofs${offset}.json"

	curl "https://registration.banner.gatech.edu/StudentRegistrationSsb/ssb/searchResults/searchResults?txt_term=${term}&pageOffset=${offset}&pageMaxSize=${page_size}&sortColumn=courseReferenceNumber&sortDirection=asc" \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Accept-Encoding: gzip, deflate, br' \
		--cookie cookies.txt \
		-H 'Connection: keep-alive' \
		-H 'Pragma: no-cache' \
		-H 'Cache-Control: no-cache' \
		--silent \
		> "$file"

	rec_count="$(jq < "$file" '.data | length')"
	total_count="$(jq < "$file" '.totalCount')"

	total_retrieved=$((total_retrieved + rec_count))

	echo "    Fetched ${rec_count} courses (${total_retrieved} / ${total_count})"

	if [ "$rec_count" -lt "$page_size" ]; then
		echo "    Done fetching."
		break
	fi

	offset=$((offset + page_size))
done

	
