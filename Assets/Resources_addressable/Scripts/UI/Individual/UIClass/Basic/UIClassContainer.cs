using System.Collections.Generic;

public class UIClassContainer{
    public UIClassContainer(){
        
        UIClass._add("UIContainer", new (){
            class_type = "UIContainer",
            // base_type = "UIContainer",
            background_key = "ui_RoundedIcon_16",
            sizeDelta = new (64, 64),
            interactions = new List<string>() {
                "UIDrop",
                "UIPassScroll2Parent"
            },
        });

        UIClass._add("UIScrollStorehouse", new UIScrollInventoryInfo(){
            class_type = "UIScrollStorehouse",
            base_type = "UIScrollStorehouse",
            prefab_key = "ScrollView",
            background_key = "ui_RoundedIcon_32",
            sizeDelta = new (512, 768),
            interactions = new List<string>() {
                "UIDrag",
            },
            subUIs = new(){
                new() { class_type = "UICloseButtom", sizeDelta = new(24, 24), anchoredPosition = new(-16, -16) },
                new() { class_type = "UIResizeButtom", sizeDelta = new(24, 24), anchoredPosition = new(-16, 16) },
            },
        });
        

        
        
        UIClass._add("UIScrollView", new UIScrollViewInfo(){
        // readonly public static UIScrollViewInfo UIScrollView = new() {
            class_type = "UIScrollView",
            base_type = "UIScrollView",
            prefab_key = "ScrollView",
            background_key = "ui_RoundedIcon_32",
            sizeDelta = new(620, 240),
            subUIs = new(){
                new() { class_type = "UICloseButtom" },
                new() { class_type = "UIResizeButtom" },
            },
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrag",
            },
        });

        
    }
}