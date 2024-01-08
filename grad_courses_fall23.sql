
select
    subject,
    number,
    course_title,
    group_concat(f.name, '; ') as faculty
from sections
join course_faculty cf on sections.id = cf.course_id
join faculty f on cf.faculty_id = f.id
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
join faculty f on cf.faculty_id = f.id
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

excluded(subject, number) as
(values
    ('CS', '6210'), -- Adv. OS, already took this

    -- From email, "MSCS Previously Attended GT"
    ('CS', '6422'), -- Database, already took this.
    ('CS', '6290'), ('ECE', '4100'), ('ECE', '6100') -- Architecture, took this undergrad.
)

select
    requirements.why,
    crn,
    sections.subject as subject,
    sections.number as number,
    sections.section as section,
    sections.course_title as course_title,
    sections.max_enrollment as max_enrollment,
    sections.enrollment as enrollment,
    sections.seats_available
from sections
left outer join requirements on requirements.subject = sections.subject and requirements.number = sections.number
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
ideas(subject, number, section) as
(values
    ('CS', '6515', null),   -- Computability, Algorithms, and Complexity (not technically core, but still required)
    ('CS', '6235', null),   -- Real-time systems concepts and implementation
    ('CS', '6211', null),   -- System design for cloud computing
    ('CS', '6747', null),   -- Advanced Topics in Malware Analysis
    ('CS', '7637', null),   -- Knowledge-based AI
    ('CS', '7650', null),   -- Natural Language
    ('CSE', '8803', 'EPI'), -- Epidemeology
    ('CS', '6250', null),   -- Computer networks
    ('CS', '6260', null),   -- Applied Cryptography
    ('CS', '6262', null),   -- Network Security
    ('CS', '6263', null),   -- Intro to Cyber-Physical Systems Security
    ('CS', '7210', null),   -- Distributed Computing
    ('CS', '8803', 'CIF'),  -- Critical Infrastructure Security
    ('CS', '8803', 'EA'),   -- Explainable AI
    ('CS', '8803', 'SII'),  -- Securing the Internet Infrastructure
    ('CS', '8803', 'SPD')   -- Security, Privacy, & Democracy
)

select
    s.crn, s.subject, s.number, s.section, s.course_title, s.seats_available,
    r.why as why,
    group_concat(f.name, '; ') as faculty
from sections s
left outer join course_faculty cf on s.id = cf.course_id
left outer join faculty f on cf.faculty_id = f.id
left outer join requirements r on s.number = r.number and s.subject = r.subject
where
    exists (
        select * from ideas
         where
            ideas.subject = s.subject
            and ideas.number = s.number
            and (ideas.section is null or ideas.section = s.section)
    )
    and (s.campus is null or s.campus like '%Atlanta%')
    and (seats_available is null or seats_available > 0)
group by s.subject, s.number, s.section
order by s.subject, s.number, s.section;