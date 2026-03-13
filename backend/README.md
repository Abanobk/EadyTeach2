# Smart Survey Backend Integration

This folder contains the backend components for the Smart Survey module.

## Setup

1. **Run the SQL schema** on your MySQL database:
   ```bash
   mysql -u your_user -p your_database < surveys_schema.sql
   ```

2. **Integrate the PHP procedures** into your existing tRPC router. The file `surveys_procedures.php` contains:
   - `surveys_create($input, $ctx)` → procedure `surveys.create`
   - `surveys_mySurveys($ctx)` → procedure `surveys.mySurveys`

   Your router must:
   - Resolve the current user from the session (e.g. `$ctx['userId']` or `$ctx['user']['id']`)
   - Provide a PDO connection as `$db`
   - Use the same tRPC format as your existing procedures (tasks, quotations)

## Procedures

### surveys.create (Mutation)
Stores a new survey. Payload fields:
- `projectName`, `clientId`, `clientEmail`
- `floors`, `rooms` (JSON)
- `lightingLines`, `switchGroups`, `acUnits`, `tvUnits`
- `curtains`, `curtainMeters`, `sensors`, `notes`

### surveys.mySurveys (Query)
Returns all surveys where `client_id` matches the current logged-in user.
Used by clients on the "معايناتي" (My Surveys) tab.
