# GitHub仓库批量删除工具

这个工具提供了批量删除GitHub仓库的脚本，支持Windows和Unix/Linux/Mac系统。脚本会自动列出你的所有仓库，让你选择要删除的仓库。

## 使用前准备：获取GitHub访问令牌

1. 登录你的GitHub账号

2. 获取个人访问令牌：
   - 点击右上角你的头像
   - 选择 "Settings"（设置）
   - 滚动到底部，点击左侧菜单中的 "Developer settings"（开发者设置）
   - 点击左侧的 "Personal access tokens"（个人访问令牌）
   - 选择 "Tokens (classic)"
   - 点击 "Generate new token"（生成新令牌）
   - 选择 "Generate new token (classic)"

3. 配置令牌：
   - 在 "Note" 中输入描述（例如："Delete Repositories Token"）
   - 设置令牌的有效期（建议选择短期，如7天或30天）
   - 在权限选项中：
     - 完整勾选 "repo" 下的所有选项
     - 特别确保 `delete_repo` 权限被选中
     - 如果要删除组织的仓库，还需要勾选 "admin:org"

4. 点击页面底部的 "Generate token"（生成令牌）按钮

5. **重要：** 立即复制生成的令牌！这是唯一能看到完整令牌的机会

## 系统要求

### Windows系统：
- Windows 10 或更高版本
- PowerShell 5.0 或更高版本
- curl（Windows 10已内置）

### Mac/Linux系统：
- curl
- jq（用于处理JSON数据）
  ```bash
  # Mac安装jq
  brew install jq
  
  # Linux安装jq
  sudo apt-get install jq  # Ubuntu/Debian
  sudo yum install jq      # CentOS/RHEL
  ```

## 使用方法

### Windows系统：
```batch
delete_repos.bat <你的GitHub令牌>
```

### Mac/Linux系统：
```bash
# 首先赋予脚本执行权限
chmod +x delete_repos.sh

# 运行脚本
./delete_repos.sh <你的GitHub令牌>
```

## 使用流程

1. 运行脚本后，会显示你的所有仓库列表，包含以下信息：
   - 序号
   - 仓库名称
   - 类型（私有/公开）
   - 主要编程语言
   - 最后更新时间

2. 输入要删除的仓库编号：
   - 可以输入多个编号，用空格分隔
   - 使用方向键可以编辑输入
   - 输入 'q' 可以退出程序

3. 确认删除列表：
   - 脚本会显示选中仓库的详细信息
   - 再次确认是否删除

4. 输入 'y' 确认删除操作

## 注意事项

- 删除操作是不可逆的，请确保要删除的仓库选择正确
- 请妥善保管你的GitHub访问令牌，使用完后建议立即删除
- 确保你有删除仓库的权限（仓库所有者或有相应权限的组织成员）
- 如果遇到 "Must have admin rights to Repository" 错误，说明令牌权限不足，需要重新生成令牌并确保勾选了 `delete_repo` 权限

## 安全建议

1. 令牌使用完毕后，建议立即删除：
   - 返回GitHub的Personal access tokens页面
   - 找到对应的令牌
   - 点击 "Delete" 删除它

2. 永远不要：
   - 将令牌分享给他人
   - 将令牌提交到代码仓库
   - 在不安全的地方保存令牌
