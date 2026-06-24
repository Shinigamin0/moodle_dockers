CREATE TABLE posgrado (
user_id VARCHAR(9) NOT NULL,
course_id VARCHAR(5) NOT NULL,
user_role VARCHAR(15) NOT NULL,
PRIMARY KEY (user_id, course_id, user_role)
);

INSERT INTO posgrado (user_id, course_id, user_role) VALUES ('000000011', '00001', 'editing-teacher');
INSERT INTO posgrado (user_id, course_id, user_role) VALUES ('000000001', '00001', 'student');
