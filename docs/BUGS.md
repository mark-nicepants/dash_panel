

1. The logs are not properly saved to the log file, see example below:
```bash
0ms) -> 1 rows
) -> 10 rows
?, ?, ?, ?, ?, ?) [null, page_views, counter, 1.0, {"path":"/admin/resources/user","method":"GET","device_type":"desktop","browser":"Chrome"}, 2025-12-06T16:29:05.373476] (1.62ms) -> 1 rows
[2025-12-06 16:29:05] [REQUEST] GET     /admin/assets/css/dash.css -> 200 (5.42ms)
[2025-12-06 16:29:05] [REQUEST] GET     /admin/assets/js/app.js -> 200 (0.16ms)
 (0.33ms)
[2025-12-06 16:29:05] [REQUEST] GET     /admin/events/stream -> 200 (1.79ms)
ue, tags, recorded_at) VALUES (?, ?, ?, ?, ?, ?) [null, page_views, counter, 1.0, {"path":"/admin/events/stream","method":"GET","device_type":"desktop","browser":"Chrome"}, 2025-12-06T16:29:05.610512] (0.81ms) -> 1 rows
[2025-12-06 16:29:05] [REQUEST] GET     /favicon.ico -> 404 (0.24ms)
```

I think we need a LogWriter class that can be used to write to a file, because multiple requests are trying to write to the same file.

2. When the server starts it should create a new log file, and append to it.

3. The relation fields require to many fields. This should be enough:

For has many:
  HasManySelect('roles') 
    .displayColumn('name')
    .required();

For belongs to:
    RelationshipSelect.make('author')
    .displayColumn('name')
    .required(),

The search columns van be the same as the display column by default. 
The valueColumn can be inferred fro the relation on the model.
The label can be ucFirst of the make input name (lets make this the default for all fields)

