using UnityEngine;
using System.Collections.Generic;
using System;
using Newtonsoft.Json;

public class UIAttributeManagerInfo: UIScrollViewInfo{
    
    [JsonProperty("textSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _textSize;
    private Vector2 _textSize_default { get => new(512, 32); }
    [JsonIgnore] public Vector2 textSize { get => _textSize ?? _textSize_default; set => _textSize = value; }

    [JsonProperty("separatorSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _separatorSize;
    private Vector2 _separatorSize_default { get => new(512, 8); }
    [JsonIgnore] public Vector2 separatorSize { get => _separatorSize ?? _separatorSize_default; set => _separatorSize = value; }

}

public class UIAttributeManager: UIScrollView{
    // ---------- Config ---------- //
    public new UIAttributeManagerInfo _info {get => (UIAttributeManagerInfo)base._info; set => base._info = value; }


    public UIAttributeManager(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_done(){
        base._init_done();
        draw_editors();
    }

    void draw_editors(){
        UIBase owner = _UISys._UIMonitor._get_UI(_info.attributes["MENU_OWNER"].get<int>());
        List<UIInfo> editors_infos = new List<UIInfo>();
        List<UIInfo> editor_infos = new();
        foreach (string key in owner._info.attributes.Keys){
            Type type = owner._info.attributes[key].get().GetType();

            if (type == typeof(string)) editor_infos = _get_editorString(owner, key);
            else Debug.Log("UIAttributeManager not support type: " + key + " " + type);

            editors_infos.Add(_get_editor_title(key));
            editors_infos.AddRange(editor_infos);
            editors_infos.Add(_get_editor_separator());
        }
        editors_infos.RemoveAt(editors_infos.Count - 1);
        for(int i = 0; i < editors_infos.Count; i++){
            _append_and_draw_item(editors_infos[i], needPlace:(i == editors_infos.Count - 1));
        }
        // return infos;
    }

    UIInfo _get_editor_title(string key){
        UIScrollTextInfo info = (UIScrollTextInfo)UIClass._set_default("UIScrollText");
        info.minSize = info.maxSize = _info.textSize;
        info.text = key;
        return info;
    }
    
    UIInfo _get_editor_separator(){
        UIInfo info = UIClass._set_default("UISeparator");
        info.sizeDelta = _info.separatorSize;
        return info;
    }

    List<UIInfo> _get_editorString(UIBase owner, string key){
        List<UIInfo> infos = new List<UIInfo>();
        string UI_type;

        UI_type = "UIScrollText";
        UIScrollTextInfo info_text = (UIScrollTextInfo)UIClass._set_default(UI_type);
        info_text.minSize = _info.textSize;
        info_text.maxSize = _info.textSize;
        info_text.messageID = _runtimeID.ToString();
        info_text.text = owner._info.attributes[key].get<string>();
        infos.Add(info_text);
        
        UI_type = "UIInputField";
        UIInfo info_input = UIClass._set_default(UI_type);
        info_input.sizeDelta = _info.textSize;
        info_input.messageID = _runtimeID.ToString();
        infos.Add(info_input);

        return infos;
    }


    public override void _update_UIMonitor(GameObject parent){
        remove_old_attributeManager();
        base._update_UIMonitor(parent);
    }

    void remove_old_attributeManager(){
        UIBase ui = _UISys._UIMonitor._get_UI_fg(_info.name);
        if (ui == null) return;
        ui._destroy();
    }

}
