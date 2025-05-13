using UnityEngine;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;

public class UIScrollInventoryInfo: UIScrollViewInfo{
}

public class UIScrollInventory: UIScrollView{
    // ---------- Config ---------- //
    public new UIScrollInventoryInfo _info {get => (UIScrollInventoryInfo)base._info; set => base._info = value; }

    public UIScrollInventory(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_done(){
        base._init_done();
        draw_container().Forget();
    }

    async UniTask draw_container(){
        int num_item = _MatSys._tile._infos.items.Count + 1; // +1 for empty tile
        List<UIInfo> containers_infos = new();
        for (int i = 0; i < num_item; i++){
            UIInfo info = UIClass._set_default("UIContainer");
            info.name = $"UIContainer {i+1}";
            containers_infos.Add(info);
        }

        for(int i = 0; i < num_item; i++){
            await _append_and_draw_item(containers_infos[i], needPlace:(i == num_item - 1));
        }
        await draw_items();
    }

    async UniTask draw_items(){
        int item_index = 0;
        UIBase UI = await draw_item(GameConfigs._sysCfg.TMap_empty_tile);
        drop_item(UI, item_index);
        item_index++;
        foreach(string key in _MatSys._tile._infos.items.Keys){
            // if (_MatSys._tile._check_sprite_loaded(key)){
            if (true){
                UI = await draw_item(key);
                drop_item(UI, item_index);
            }
            item_index++;
        }
    }

    async UniTask<UIBase> draw_item(string key){
        UIInfo info = UIClass._set_default("UITileThumb", key);
        UIBase UI = UIDraw._draw_UI(_UISys._foreground, "UITileThumb", info);
        // await UI.set_background(_MatSys._tile._get_sprite(key, "__Full"));
        // await UI.set_background(_MatSys._tile._get_sprite(key, "__Full"));
        return UI;
    }

    void drop_item(UIBase UI, int index){
        if (items[index]._InteractMgr._interactions.TryGetValue(nameof(UIDrop), out var interaction)){
            if (interaction is UIDrop drop) {
                drop.drop(UI);
            }
        }
        else{
            Debug.LogError("items[item_index] dont contain interaction UIDrop, I think this error will no happen");
        }
    }

}
