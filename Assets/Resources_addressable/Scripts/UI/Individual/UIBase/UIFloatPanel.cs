using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using Newtonsoft.Json;
using Cysharp.Threading.Tasks;


public class UIFloatPanelInfo: UIScrollViewInfo{
    
    [JsonProperty("textMinSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _textMinSize;
    private Vector2 _textMinSize_default { get => new(512, 32); }
    [JsonIgnore] public Vector2 textMinSize { get => _textMinSize ?? _textMinSize_default; set => _textMinSize = value; }

    [JsonProperty("textMaxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _textMaxSize;
    private Vector2 _textMaxSize_default { get => new(512, 96); }
    [JsonIgnore] public Vector2 textMaxSize { get => _textMaxSize ?? _textMaxSize_default; set => _textMaxSize = value; }

    [JsonProperty("inputTextSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _inputTextSize;
    private Vector2 _inputTextSize_default { get => new(512, 32); }
    [JsonIgnore] public Vector2 inputTextSize { get => _inputTextSize ?? _inputTextSize_default; set => _inputTextSize = value; }

    [JsonProperty("ButtonSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _buttonSize;
    private Vector2 _buttonSize_default { get => new(128, 32); }
    [JsonIgnore] public Vector2 buttonSize { get => _buttonSize ?? _buttonSize_default; set => _buttonSize = value; }

    [JsonProperty("separatorSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _separatorSize;
    private Vector2 _separatorSize_default { get => new(512, 4); }
    [JsonIgnore] public Vector2 separatorSize { get => _separatorSize ?? _separatorSize_default; set => _separatorSize = value; }

}

public class UIFloatPanel: UIScrollView{
    public new UIFloatPanelInfo _info {get => (UIFloatPanelInfo)base._info; set => base._info = value; }

    public UIFloatPanel(GameObject parent, UIFloatPanelInfo info = null): base(parent, info){
    }

    public override void _enable(){
        base._enable();
        Debug.Log("enable");
        if (_UISys._UIMonitor.ui_currentPointerEnter != null){
            // ---------- UI ---------- //
            Debug.Log(_UISys._UIMonitor.ui_currentPointerEnter._info.name);
        }
        else{
            // ---------- Tilemap Tile ---------- //
            _clear();
            draw_floatPanel("tile").Forget();
        }
    }

    public override void _disable(){
        base._disable();
    }
    
    async UniTask draw_floatPanel(string type){
        await _wait_init_done();
        List<UIInfo> floatPanel_infos = new List<UIInfo>();

        if (type == "tile") floatPanel_infos.AddRange(get_floatPanel_tile());

        for(int i = 0; i < floatPanel_infos.Count; i++){
            await _append_and_draw_item(floatPanel_infos[i], needPlace:(i == floatPanel_infos.Count - 1));
        }
        // return infos;
    }

    UIInfo get_title(string title){
        UIScrollTextInfo info = (UIScrollTextInfo)UIClass._set_default("UITitleText");
        info.minSize = _info.textMinSize;
        info.maxSize = _info.textMaxSize;
        info.text = title;
        return info;
    }

    UIInfo get_separator(){
        UIInfo info = UIClass._set_default("UISeparator");
        info.sizeDelta = _info.separatorSize;
        return info;
    }

    List<UIInfo> get_floatPanel_tile(){
        Vector2 world_pos = InputSystem._keyPos.mouse_pos_world;
        Vector3Int map_pos = TilemapAxis._mapping_worldPos_to_mapPos(world_pos, new());
        TilemapTile tile = TilemapTile._get(new LayerType(), map_pos);

        List<UIInfo> infos = new List<UIInfo>();
        // string UI_type;

        infos.Add(get_title("Tile"));
        infos.Add(get_separator());
        if (tile != null){
            infos.Add(get_title($"ID: {tile.tile_ID}"));
            infos.Add(get_title($"subID: {tile.tile_subID}"));
            // infos.Add(get_title($"show ID: {tile.__tile_ID}"));
            // infos.Add(get_title($"show sub_ID: {tile.__tile_subID}"));
            // infos.Add(get_title($"actual sub_ID: {tile.__actual_subID}"));
            
        }
        else{
            infos.Add(get_title("No Tile"));
        }


        return infos;
    }
}
