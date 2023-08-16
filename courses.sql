select
    number,
    subject,
    subject_description,
    section,
    campus,
    schedule_type,
    course_title,
    credit_hours,
    sum(max_enrollment) as max_enrollment,
    sum(enrollment) as enrollment,
    sum(waitlist_capacity) as waitlist_capacity,
    sum(waitlist_count) as waitlist_count,
    sum(waitlist_available) as waitlist_available,
    group_concat(attributes, ';') as attributes
from sections
where
    course_title not like '% Thesis%'
    and course_title not like '% Project'
    and course_title not like '% Research'
    and course_title not like '%Research Assistantship'
    and number not like '??97'
    and number not like '??98'
    and number not like '??99'
group by subject,number;