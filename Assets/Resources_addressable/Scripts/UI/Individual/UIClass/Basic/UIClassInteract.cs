using System.Collections.Generic;

public class UIClassInteract{
    public UIClassInteract(){
        UIClass._add("UIExecuteCommandFromAttribute", new UIScrollTextInfo(){
            class_type="UIExecuteCommandFromAttribute", base_type = "UIScrollText", prefab_key = "ScrollText",
            background_key="ui_RoundedIcon_8", PixelsPerUnitMultiplier=1, 
            attributes = new() {
                {"COMMAND", "" },
            },
            interactions = new List<string>() {
                "UIExecuteCommandFromAttribute",
                "UIPassScroll2Parent"
            },
        });
    }
}