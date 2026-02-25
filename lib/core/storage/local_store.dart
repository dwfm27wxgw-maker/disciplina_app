    lib/features/home/screens/home_page.dart:403:25: Error: The method 'AddMovementScreen' isn't defined for the type '_HomePageState'.
     - '_HomePageState' is from 'package:disciplina_app/features/home/screens/home_page.dart' ('lib/features/home/screens/home_page.dart').
    Try correcting the name to the name of an existing method, or defining a method named 'AddMovementScreen'.
            builder: (_) => AddMovementScreen(
                            ^^^^^^^^^^^^^^^^^
    lib/core/storage/local_store.dart:28:29: Error: Undefined name 'LocalStore'.
        final monthDone = await LocalStore.getMonthDone(year: y, month: m);
                                ^^^^^^^^^^
    lib/core/storage/local_store.dart:101:23: Error: Undefined name 'LocalStore'.
          final m = await LocalStore.getMovements();
                          ^^^^^^^^^^
    lib/core/storage/local_store.dart:110:20: Error: Undefined name 'LocalStore'.
          return await LocalStore.getPlan();
                       ^^^^^^^^^^
    lib/features/coach/screens/monthly_digest_screen.dart:14:3: Error: 'MonthlyDigest' isn't a type.
      MonthlyDigest? _digest;
      ^^^^^^^^^^^^^
    lib/features/coach/screens/monthly_digest_screen.dart:29:23: Error: The getter 'MonthlyDigestService' isn't defined for the type '_MonthlyDigestScreenState'.
     - '_MonthlyDigestScreenState' is from 'package:disciplina_app/features/coach/screens/monthly_digest_screen.dart' ('lib/features/coach/screens/monthly_digest_screen.dart').
    Try correcting the name to the name of an existing getter, or defining a getter or field named 'MonthlyDigestService'.
          final d = await MonthlyDigestService.buildMonthlyDigest();
                          ^^^^^^^^^^^^^^^^^^^^
    lib/features/plan/screens/edit_plan_screen.dart:35:21: Error: The getter 'LocalStore' isn't defined for the type '_EditPlanScreenState'.
     - '_EditPlanScreenState' is from 'package:disciplina_app/features/plan/screens/edit_plan_screen.dart' ('lib/features/plan/screens/edit_plan_screen.dart').
    Try correcting the name to the name of an existing getter, or defining a getter or field named 'LocalStore'.
        final p = await LocalStore.getPlan();
                        ^^^^^^^^^^
    lib/features/plan/screens/edit_plan_screen.dart:86:11: Error: The getter 'LocalStore' isn't defined for the type '_EditPlanScreenState'.
     - '_EditPlanScreenState' is from 'package:disciplina_app/features/plan/screens/edit_plan_screen.dart' ('lib/features/plan/screens/edit_plan_screen.dart').
    Try correcting the name to the name of an existing getter, or defining a getter or field named 'LocalStore'.
        await LocalStore.savePlan(
              ^^^^^^^^^^
    lib/features/home/screens/add_movement_screen.dart:26:57: Error: Expected '{' before this.
    jesusmoralesordas@MacBook-Pro-de-jesus disciplina_app % 
                                                            ^...
    lib/features/home/screens/add_movement_screen.dart:2:16: Error: Expected a function body, but got '^'.
                  ^^^^^^^^^^
                   ^
    lib/features/home/screens/add_movement_screen.dart:2:16: Error: Expected a function body, but got '{'.
                  ^^^^^^^^^^
                   ^
    lib/features/coach/services/monthly_digest_service.dart:75:13: Error: The getter 'LocalStore' isn't defined for the type '_AddMovementScreenState'.
     - '_AddMovementScreenState' is from 'package:disciplina_app/features/coach/services/monthly_digest_service.dart' ('lib/features/coach/services/monthly_digest_service.dart').
    Try correcting the name to the name of an existing getter, or defining a getter or field named 'LocalStore'.
          await LocalStore.saveMovement(m);
                ^^^^^^^^^^
    Target kernel_snapshot_program failed: Exception
    Failed to package /Users/jesusmoralesordas/Dev/disciplina_app.
    Command PhaseScriptExecution failed with a nonzero exit code
    /Users/jesusmoralesordas/Dev/disciplina_app/ios/Pods/Pods.xcodeproj: warning: The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 11.0, but the range of supported deployment target
    versions is 12.0 to 26.2.99. (in target 'flutter_timezone-flutter_timezone_privacy' from project 'Pods')
    /Users/jesusmoralesordas/Dev/disciplina_app/ios/Pods/Pods.xcodeproj: warning: The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 11.0, but the range of supported deployment target
    versions is 12.0 to 26.2.99. (in target 'flutter_local_notifications-flutter_local_notifications_privacy' from project 'Pods')
    note: Run script build phase 'Run Script' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'Runner' from project 'Runner')
    note: Run script build phase 'Thin Binary' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'Runner' from project 'Runner')

Could not build the application for the simulator.
Error launching application on iPhone 16e.
jesusmoralesordas@MacBook-Pro-de-jesus disciplina_app % ls ~/Dev     
disciplina_app	disciplina_test
