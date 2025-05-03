using UnityEngine;
using System.Collections.Generic;
using System;
using Newtonsoft.Json;
using System.Text.RegularExpressions;
using Cysharp.Threading.Tasks;

public class UIContainerInfo: UIScrollViewInfo{
    
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

public class UIScrollStorehouse: UIScrollView{
    // ---------- Config ---------- //
    public new UIContainerInfo _info {get => (UIContainerInfo)base._info; set => base._info = value; }
    UIBase owner;

    public UIScrollStorehouse(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_done(){
        base._init_done();
        draw_container().Forget();
    }

    async UniTask draw_container(){
        int num_item = _MatSys._tile._infos.items.Count;
        List<UIInfo> containers_infos = new List<UIInfo>();
        int container_ID = 0;
        foreach(string key in _MatSys._tile._infos.items.Keys){
            UIInfo info = UIClass._set_default("UIContainer");
            container_ID++;
            info.name = $"UIContainer {container_ID}";
            containers_infos.Add(info);
        }

        for(int i = 0; i < containers_infos.Count; i++){
            await _append_and_draw_item(containers_infos[i], needPlace:(i == containers_infos.Count - 1));
        }
    }

}
