CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(255) NOT NULL
);

CREATE TABLE items (
	id SERIAL PRIMARY KEY,
	label VARCHAR(255) NOT NULL
);

CREATE TABLE user_items (
	user_id INT,
	item_id INT
);

-- mock data
INSERT INTO items(label)
VALUES ('fork'),
	('knife'),
	('apple'),
	('pear'),
	('mango'),
	('coke'),
	('keyboard'),
	('piano'),
	('guitar');

INSERT INTO users(first_name)
VALUES ('adam'),
	('benjamin'),
	('caleb');

INSERT INTO user_items (user_id, item_id)
SELECT u.id, i.id
FROM users u, items i;