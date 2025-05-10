using System.Collections.Generic;

public class UIClassFloatPanel{
    public UIClassFloatPanel(){

        UIClass._add("UIFloatPanel", new UIFloatPanelInfo(){
            class_type = "UIFloatPanel",
            base_type = "UIFloatPanel",
            background_key = "ui_RoundedIcon_32",
            PixelsPerUnitMultiplier = 1,
            prefab_key = "UIScrollView",
            paddingLeft = 16, paddingRight = 16, paddingTop = 16 + 8*2 + 16*2, paddingBottom = 16 + 8*2 + 16*2,
            spacing = new (16, 16),
            minSize = new (512, 128),
            interactions = new List<string>() {
                nameof(UIDrag),
            },
            subUIs = new(){
                new() { class_type = "UICloseButtom", sizeDelta = new(24, 24), anchoredPosition = new(-16, -16) },
                new() { class_type = "UIResizeButtom", sizeDelta = new(24, 24), anchoredPosition = new(-16, 16) },
                new() { class_type = "UITitleSeparator", anchoredPosition = new(0, -(16+32)) },
                new UIScrollTextInfo() { 
                    class_type = "UIScrollText", name = "Title",
                    minSize = new(512-32, 32), anchoredPosition = new(16, -16) ,
                    text = "Float Panel", background_key=""
                },
            }
        });
    }
}