import os
import re

def main():
    path = r'c:\Users\tonton\Downloads\ny_kitchen_app\lib\features\admin\presentation\pages\admin_dashboard_page.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pass context to helper methods
    content = re.sub(r'Widget (_build[a-zA-Z0-9_]+)\(', r'Widget \1(BuildContext context, ', content)
    content = content.replace('(BuildContext context, )', '(BuildContext context)')
    
    # Update calls
    content = content.replace('_buildPeriodChip(', '_buildPeriodChip(context, ')
    content = content.replace('_buildStatCard(', '_buildStatCard(context, ')
    content = content.replace('_buildSectionCard(', '_buildSectionCard(context, ')
    content = content.replace('_buildChartPlaceholder()', '_buildChartPlaceholder(context)')
    content = content.replace('_buildRecentTransactionsTable()', '_buildRecentTransactionsTable(context)')
    content = content.replace('_buildTopSellingList()', '_buildTopSellingList(context)')
    content = content.replace('_buildRecentActivitiesList()', '_buildRecentActivitiesList(context)')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    path = r'c:\Users\tonton\Downloads\ny_kitchen_app\lib\features\cashier\presentation\pages\account_settings_page.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('Widget _buildSettingItem(', 'Widget _buildSettingItem(BuildContext context, ')
    content = content.replace('_buildSettingItem(', '_buildSettingItem(context, ')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
