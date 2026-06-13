import re

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/edit_user_screen.dart', 'r') as f:
    content = f.read()

# 1. Fix PopScope
# The python script generated:
#       },
#       child: Scaffold(
#       backgroundColor: AppColors.surface,
# So the Scaffold is missing a closing parenthesis.
# In the original file, we replaced "    return Scaffold(" with PopScope(... child: Scaffold(
# Which means Scaffold's closing parenthesis is there, but PopScope's is missing!
# The script did:
# content = content.replace("    );\n  }\n}\n\nclass _EditSectionCard", "    ),\n    );\n  }\n}\n\nclass _EditSectionCard")
# Which should have closed the PopScope, but it might not have matched if the spacing was different.

# Let's fix the missing parenthesis around PopScope.
# Around line 220:
content = content.replace("url: widget.photoUrl!", "imageUrl: widget.photoUrl!")

# 2. Remove _showDiscardDialog from other classes
# Let's identify the block of _showDiscardDialog
discard_dialog_str = """
  Future<bool?> _showDiscardDialog() {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard changes?', style: TextStyle(color: AppColors.primary)),
        content: Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {"""

# Find all occurrences of this block and replace with standard build method, EXCPET the first one
parts = content.split(discard_dialog_str)
if len(parts) > 1:
    # First split is before the first occurrence (which is correct in _EditUserScreenState)
    # The rest are incorrect occurrences in other classes.
    new_content = parts[0] + discard_dialog_str + parts[1]
    for part in parts[2:]:
        new_content += "  @override\n  Widget build(BuildContext context) {" + part
    content = new_content

# Now fix the missing closing parenthesis for PopScope.
# We know the state class ends before "class _EditSectionCard" or "List<_GenderOption> _genderOptions"
# Actually, the original file had `_genderOptions` at the end of the state class.
# Let's just find the end of `_genderOptions`
if "    ];\n  }\n}" in content:
    content = content.replace("    ];\n  }\n}", "    ];\n  }\n}\n")
    
# Wait, if `return PopScope(... child: Scaffold(...` was opened in `build`, we need to close `PopScope` where `Scaffold` closes.
# `Scaffold` is the return statement of `build` in `_EditUserScreenState`.
# So it closes right before `List<_GenderOption> _genderOptions(AppLocalizations t)` or similar.
# Let's see the end of `build` in `_EditUserScreenState`.

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/edit_user_screen.dart', 'w') as f:
    f.write(content)
