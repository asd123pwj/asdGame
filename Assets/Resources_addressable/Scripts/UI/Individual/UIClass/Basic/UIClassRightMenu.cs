using System.Collections.Generic;

public class UIClassRightMenu{
    public UIClassRightMenu(){

        
        // UIClass._add("UIRightMenu", new (){
        // // readonly public static UIInfo UIRightMenu = new() {
        //     type = "UIRightMenu",
        //     background_key = "RightMenu",
        //     // enableNavigation = true,
        //     sizeDelta = new (300, 200),
        //     interactions = new List<string>() {
        //         // "UISetTop",
        //         // "UIDeselectClose",
        //     },
        // });

        UIClass._add("UIRightMenuInteractionManager", new (){
            type = "UIRightMenuInteractionManager",
            base_type = "UIRightMenu",
            background_key = "RightMenu",
            sizeDelta = new (190 + 40, 230 + 40),
            subUIs = new(){
                new UIScrollViewInfo() {
                    type = "UIScrollView",
                    base_type = "UIScrollView",
                    sizeDelta = new (150*1 + 20*0 + 20 + 20, 50*3 + 20*2 + 20 + 20),
                    anchoredPosition = new (20, -20),
                    interactions = new List<string>() {
                    },
                    items = new(){
                        new() {
                            name = "UIImage",
                            type = "UIImage",
                        },
                    },
                    subUIs = new()
                }
            }
        });

        
    }
}