
select
    subject,
    number,
    course_title,
    group_concat(f.name, '; ') as faculty
from sections
join course_faculty cf on sections.id = cf.course_id
join faculty f on cf.faculty_id = f.banner_id
group by subject, number;

select
    subject,
    number,
    course_title,
    section,
    campus,
    attributes,
    group_concat(f.name, '; ') as faculty
from sections
join course_faculty cf on sections.id = cf.course_id
join faculty f on cf.faculty_id = f.banner_id
where
    subject = 'CS'
    and campus like '%Atlanta%'
    and course_title not like '% Thesis%'
    and course_title not like '% Project'
    and course_title != 'Special Problems'
    and number between 6000 and 9999
group by subject, number
order by number;


