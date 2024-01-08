-- Courses I want
with
wishlist(subject, number) as
(values
    -- In order of decreasing priority:
    ('CS', '6515'), -- Intro to Graduate Algorithms
    ('CS', '6390'),  -- Programming Language Design
    ('CSE', '6230') -- High Performance Parallel Computing
)
select
    crn, subject, number, section, course_title,
    open,
    enrollment, max_enrollment, seats_available,
    waitlist_capacity, waitlist_count, waitlist_available,
    attributes,
    raw
from available_sections
where (subject, number) in (select subject, number from wishlist)
;

select raw from sections;


select
    subject, number, course_title,
    sum(seats_available) as total_seats_available
from available_sections
where
    open = 'true'
    and number > 6000
    and (subject = 'CS' or subject = 'CSE')
group by subject, number
order by number
;

select sections.*, group_concat(f.name, '; ') as faculty
from sections
join course_faculty cf on sections.id = cf.course_id
join faculty f on cf.faculty_id = f.id
where section = 'SSA'
group by subject, number, section
;

