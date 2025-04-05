using System.Collections.Generic;

public class UIClassContainer{
    public UIClassContainer(){
        
        UIClass._add("UIContainer", new (){
        // readonly public static UIInfo UIContainer = new() {
            type = "UIContainer",
            background_key = "",
            sizeDelta = new (800, 800),
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrop",
                "UIScrollPass2Parent"
            },
        });

        

        
        
        UIClass._add("UIScrollView", new UIScrollViewInfo(){
        // readonly public static UIScrollViewInfo UIScrollView = new() {
            type = "UIScrollView",
            base_type = "UIScrollView",
            prefab_key = "ScrollView",
            background_key = "Empty",
            // anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new(0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
            sizeDelta = new(620, 240),
            constraintCount = 3,
            subUIs = new(){
                new() { type = "UICloseButtom" },
                new() { type = "UIResizeButtom" },
            },
            // subUIs = new Dictionary<string, List<UIInfo>>(){
            //     { "ControlUIs", new (){
            //         new() { type = "UICloseButtom" },
            //         new() { type = "UIResizeButtom" },
            //     } },
            // },
            interactions = new List<string>() {
                // "UISetTop",
                "UIDrag",
            },
        });

        
    }
}