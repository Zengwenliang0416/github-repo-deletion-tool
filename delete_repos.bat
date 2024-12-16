@echo off
setlocal enabledelayedexpansion

REM 检查是否提供了GitHub个人访问令牌
if "%~1"=="" (
    echo 请提供GitHub个人访问令牌
    echo 使用方法: delete_repos.bat ^<github_token^>
    exit /b 1
)

set TOKEN=%~1

REM 创建PowerShell脚本来处理JSON数据
echo $token = '%TOKEN%' > process_repos.ps1
echo $headers = @{ >> process_repos.ps1
echo     Authorization = "token $token" >> process_repos.ps1
echo     Accept = "application/vnd.github.v3+json" >> process_repos.ps1
echo } >> process_repos.ps1
echo. >> process_repos.ps1
echo Write-Host "正在获取你的仓库列表..." >> process_repos.ps1
echo $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos?per_page=100" -Headers $headers >> process_repos.ps1
echo. >> process_repos.ps1
echo Write-Host "你的仓库列表：" >> process_repos.ps1
echo Write-Host "--------------------------------------------------------------------------------------------------------" >> process_repos.ps1
echo $format = "{0,-4} {1,-50} {2,-10} {3,-15} {4,-20}" >> process_repos.ps1
echo $format -f "序号", "仓库名称", "类型", "语言", "最后更新时间" >> process_repos.ps1
echo Write-Host "--------------------------------------------------------------------------------------------------------" >> process_repos.ps1
echo. >> process_repos.ps1
echo if ($response) { >> process_repos.ps1
echo     $index = 1 >> process_repos.ps1
echo     $response | ForEach-Object { >> process_repos.ps1
echo         $repoType = if ($_.private) { "私有" } else { "公开" } >> process_repos.ps1
echo         $language = if ($_.language) { $_.language } else { "未知" } >> process_repos.ps1
echo         $updatedTime = [DateTime]::Parse($_.updated_at).ToString("yyyy-MM-dd HH:mm") >> process_repos.ps1
echo         $format -f $index, $_.full_name, $repoType, $language, $updatedTime >> process_repos.ps1
echo         $_.full_name >> "all_repos.txt" >> process_repos.ps1
echo         $index++ >> process_repos.ps1
echo     } >> process_repos.ps1
echo } else { >> process_repos.ps1
echo     Write-Host "获取仓库列表失败或没有找到仓库" >> process_repos.ps1
echo     exit 1 >> process_repos.ps1
echo } >> process_repos.ps1
echo Write-Host "--------------------------------------------------------------------------------------------------------" >> process_repos.ps1

REM 执行PowerShell脚本
powershell -ExecutionPolicy Bypass -File process_repos.ps1
if errorlevel 1 (
    del process_repos.ps1
    exit /b 1
)

:input_loop
echo.
set /p "input=请输入要删除的仓库编号（多个编号用空格分隔，输入 'q' 退出）："

if "%input%"=="q" (
    echo 操作已取消
    del process_repos.ps1 all_repos.txt
    exit /b 0
)

REM 验证输入
for %%a in (%input%) do (
    set "num=%%a"
    set "valid=true"
    
    REM 检查是否为数字
    echo !num!| findstr /r "^[1-9][0-9]*$" >nul
    if errorlevel 1 (
        set "valid=false"
        echo 无效的输入：!num! 不是有效的数字
        goto input_loop
    )
    
    REM 检查范围
    for /f %%i in ('type all_repos.txt ^| find /c /v ""') do set total=%%i
    if !num! gtr !total! (
        set "valid=false"
        echo 无效的输入：!num! 超出范围
        goto input_loop
    )
)

REM 创建要删除的仓库列表
if exist repos_to_delete.txt del repos_to_delete.txt
for %%i in (%input%) do (
    set /a linenum=0
    for /f "usebackq tokens=*" %%a in ("all_repos.txt") do (
        set /a linenum+=1
        if !linenum!==%%i (
            echo %%a>>repos_to_delete.txt
        )
    )
)

REM 显示将要删除的仓库信息
echo.
echo 将要删除以下仓库：
echo --------------------------------------------------------------------------------------------------------

REM 创建PowerShell脚本来显示选中的仓库信息
echo $token = '%TOKEN%' > show_selected.ps1
echo $selectedRepos = Get-Content "repos_to_delete.txt" >> show_selected.ps1
echo $response = Get-Content "all_repos.txt" | ForEach-Object { >> show_selected.ps1
echo     if ($selectedRepos -contains $_) { >> show_selected.ps1
echo         $repo = $response | Where-Object { $_.full_name -eq $_ } >> show_selected.ps1
echo         $repoType = if ($repo.private) { "私有" } else { "公开" } >> show_selected.ps1
echo         $language = if ($repo.language) { $repo.language } else { "未知" } >> show_selected.ps1
echo         $updatedTime = [DateTime]::Parse($repo.updated_at).ToString("yyyy-MM-dd HH:mm") >> show_selected.ps1
echo         "{0,-50} {1,-10} {2,-15} {3,-20}" -f $repo.full_name, $repoType, $language, $updatedTime >> show_selected.ps1
echo     } >> show_selected.ps1
echo } >> show_selected.ps1

powershell -ExecutionPolicy Bypass -File show_selected.ps1
echo --------------------------------------------------------------------------------------------------------

set /p "confirm=确认删除这些仓库吗？(y/n)："
if /i "%confirm%"=="y" (
    for /f "usebackq tokens=*" %%a in ("repos_to_delete.txt") do (
        echo 正在删除仓库: %%a
        curl -X DELETE -H "Authorization: token %TOKEN%" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/%%a"
        if !errorlevel! equ 0 (
            echo 成功删除仓库: %%a
        ) else (
            echo 删除仓库失败: %%a
        )
    )
    echo 删除操作完成！
) else (
    echo 操作已取消
)

REM 清理临时文件
del process_repos.ps1 show_selected.ps1 all_repos.txt repos_to_delete.txt
