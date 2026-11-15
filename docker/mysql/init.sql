-- Runs once, when the MySQL container's data volume is first created.
-- The app user may create and manage every socialnetwork_* database: the main
-- one plus the _cache, _queue and _cable databases used by Solid Cache, Solid
-- Queue and Solid Cable in production.
CREATE USER IF NOT EXISTS 'socialnetwork'@'%' IDENTIFIED BY 'socialnetwork';
GRANT ALL PRIVILEGES ON `socialnetwork\_%`.* TO 'socialnetwork'@'%';
FLUSH PRIVILEGES;
