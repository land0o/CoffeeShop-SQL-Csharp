DROP TABLE IF EXISTS Coffee;

CREATE TABLE Coffee (
    Id INTEGER NOT NULL PRIMARY KEY IDENTITY,
    Title VARCHAR(50) NOT NULL,
    BeanType VARCHAR(50) NOT NULL
);

INSERT INTO Coffee (Title, BeanType)
VALUES ('Espresso', 'Brazilian');

INSERT INTO Coffee (Title, BeanType)
VALUES ('Cafe Con Leche', 'Costa Rican');

INSERT INTO Coffee (Title, BeanType)
VALUES ('Cappuccino', 'Guatemalan');