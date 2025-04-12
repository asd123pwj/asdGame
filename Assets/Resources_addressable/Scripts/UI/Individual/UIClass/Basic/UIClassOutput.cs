using System.Collections.Generic;

public class UIClassOutput{
    public UIClassOutput(){
        UIClass._add("UIScrollText", new UIScrollTextInfo(){
            type = "UIScrollText",
            base_type = "UIScrollText",
            prefab_key = "ScrollText",
            background_key = "ui_RoundedIcon_16", PixelsPerUnitMultiplier=1,
        });

        UIClass._add("UITitleText", new UIScrollTextInfo(){
            type = "UITitleText",
            base_type = "UIScrollText",
            prefab_key = "ScrollText",
            background_key = "ui_AccentLine_Left", PixelsPerUnitMultiplier=1,
        });
        
    }
}