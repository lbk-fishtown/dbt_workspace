CREATE OR REPLACE PROCEDURE 
ALBK_WORKSPACE_DEV.STORED_PROCEDURES.RUN_ALL(
  DATABASE STRING
)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
  const sqlCommands = [
    // setup
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.CREATE_TOP_LEVEL_OBJECTS(
      '${DATABASE}', 
      FALSE
    )`,
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.CREATE_SECURITY_OBJECTS(
      '${DATABASE}', 
      'Aa1 needless_good-bye', 
      'Bb1 acidic_formula', 
      FALSE
    )`,

    // process records
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.PROCESS_SNOWFLAKE_USAGE_DATA(
      '${DATABASE}'
    )`,
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.SP_BUILD_SNOWFLAKE_USAGE_MART(
      '${DATABASE}',
      FALSE
    )`,

    // teardown
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.DROP_TOP_LEVEL_OBJECTS(
      '${DATABASE}',
      FALSE
    )`,
    `CALL ALBK_WORKSPACE_DEV.STORED_PROCEDURES.DROP_SECURITY_OBJECTS(
      '${DATABASE}',
      FALSE
    )`
  ];

  
  var currCommand = 'not set yet';
  try { 
    sqlCommands.forEach((sqlCommand) => { 
      currCommand = sqlCommand;
      snowflake.execute({ sqlText: sqlCommand }); 
    });
    
  } catch (err)  {
    // tear stuff down last second to preserve pseudo idempotence. I guess?
    sqlCommands.slice(-2).forEach((sqlCommand) => { 
      snowflake.execute({ sqlText: sqlCommand }); 
    });

    return  `
      Procedure Failed. 
        Message: ${err.message}

        Last SQL Command: ${currCommand}

        Stack Trace:
        ${err.stack}
    `;
  }

  return 'Successfully ran all'
$$;
