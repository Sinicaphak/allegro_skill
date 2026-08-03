let((root files file loadPath)
    root =
        "D:/program615/allegro/skill/allegro_skill/allergo/height_check/hc_v2"

    files = list(
        "base/hc_config.il"
        "tool/hc_db.il"
        "iterate/hc_fields.il"
        "iterate/hc_placebound.il"
        "output/hc_csv.il"
        "base/hc_export.il"
        "base/hc_main.il"
    )

    foreach(file files
        loadPath = strcat(root "/" file)

        printf(
            "Loading %s...\n"
            loadPath
        )

        load(loadPath)
    )

    ; 所有依赖加载成功后再注册命令
    axlCmdRegister(
        "selfv2"
        'HC_main
    )

    printf("\n")
    printf("========================================\n")
    printf("height_check loaded successfully.\n")
    printf("Type 'selfv2' to run.\n")
    printf("========================================\n")
)
