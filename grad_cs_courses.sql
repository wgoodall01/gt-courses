
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


-- Core courses
with
core_courses(subject, number) as
(values
    ('CS', '6515'), -- Computability, Algorithms, and Complexity (not technically core, but still required)
    ('CS', '6210'), -- Operating Systems
    ('CS', '6241'), -- Compilers
    ('CS', '6250'), -- Networking
    ('CS', '6290'), -- Architecture
    ('CS', '6300'), -- Software Engineering
    ('CS', '6390'), -- Programming Language Design
    ('CS', '6400') -- Database Systems
),

elective_courses(subject, number) as
(values
    ('CS', '6035'), -- Introduction to Information Security — TR 5:00 - 6:15
    ('CS', '6200'), -- Graduate Introduction to Operating Systems — nope
    ('CS', '6220'), -- Big Data Systems and Analytics —- nope
    ('CS', '6235'), -- Real-Time System Concepts and Implementation —- nope
    ('CS', '6238'), -- Secure Computer Systems — TR 12:30 - 1:45
    ('CS', '6260'), -- Applied Cryptography — nope
    ('CS', '6262'), -- Network Security — TR 2:00 - 3:15
    ('CS', '6263'), -- Intro to Cyberphysical Systems Security — nope
    ('CS', '6291'), -- Embedded Software Optimization — nope
    ('CS', '6310'), -- Software Architecture and Design — nope
    ('CS', '6340'), -- Software Analysis and Testing — nope
    ('CS', '6365'), -- Introduction to Enterprise Computing —-
    ('CS', '6422'), -- Database System Implementation
    ('CS', '6550'), -- Design and Analysis of Algorithms
    ('CS', '6675'), -- Advanced Internet Computing Systems and Applications
    ('CS', '7210'), -- Distributed Computing
    ('CS', '7260'), -- Internetworking Architectures and Protocols
    ('CS', '7270'), -- Networked Applications and Services
    ('CS', '7280'), -- Network Science
    ('CS', '7290'), -- Advanced Topics in Microarchitecture
    ('CS', '7292'), -- Reliability and Security in Computer Architecture
    ('CS', '7560'), -- Theory of Cryptography
    ('CS', '8803'), -- Special Topics
    ('CSE', '6220') -- High Performance Computing
),

wants(subject, number, why) as (
    select subject, number, 'Core' from core_courses
    union
    select subject, number, 'Elective' from elective_courses
),

excluded(subject, number) as
(values
    ('CS', '6210'), -- Adv. OS, already took this

    -- From email, "MSCS Previously Attended GT"
    ('CS', '6422'), -- Database, already took this.
    ('CS', '6290'), ('ECE', '4100'), ('ECE', '6100') -- Architecture, took this undergrad.
)

select
    why,
    crn,
    sections.subject as subject,
    sections.number as number,
    sections.section as section,
    sections.course_title as course_title,
    sections.max_enrollment as max_enrollment,
    sections.enrollment as enrollment,
    sections.seats_available
from wants
right join sections on wants.subject = sections.subject and wants.number = sections.number
where
    not exists (select * from excluded where excluded.subject = sections.subject and excluded.number = sections.number)
    and sections.subject in ('CS', 'CSE')
    and (sections.campus is null or sections.campus like '%Atlanta%')
    and sections.number between 6000 and 9999
    and sections.course_title not like '% Thesis%'
    and sections.course_title not like '% Project'
    and sections.course_title not like '%Teaching Assistant%'
    and sections.course_title not like '%Research Assistant%'
    and sections.course_title != 'Special Problems'
order by why, number;

-- Things I'd like to take
with
ideas(subject, number) as
(values
    ('CS', '6515'), -- Computability, Algorithms, and Complexity (not technically core, but still required)
    ('CS', '6262') -- Network Security
)

select * from sections
where
    exists (select * from ideas where ideas.subject = sections.subject and ideas.number = sections.number)
    and sections.campus like '%Atlanta%';