INSERT INTO rulesets(id, label, title, bufferPayouts, uniquepayouts, wagersetid, currencysetid, defaultwager, gcd, maxwinmultiplier, rng, categorytype, categorysubtype)
VALUES(
    'cc3a7c05-a891-45f3-9cdc-543323d7a5bd', 
    'bookofbabylon', 
    'Book of Babylon', 
    TRUE, 
    TRUE, 
    'standard-slot', 
    'gjg-2020', 
    200, 
    2, 
    254257, 
    '351c0f46d337cd13c6e34ea99eddaea748d68402', 
    'Slot', 
    ''
);

INSERT INTO games(id, integrationid, rulesetid, label)
VALUES(
    '7be1ca13-ee49-42ef-b03f-1ea60b1f24be', 
    'f5594b3a-f159-4cf2-8b55-0213ca44ab0a',
    'cc3a7c05-a891-45f3-9cdc-543323d7a5bd', 
    'samplewallet-bookofbabylon'
);
