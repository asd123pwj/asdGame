using UnityEngine;
using System.Collections.Generic;
using System;
using Newtonsoft.Json;
using System.Text.RegularExpressions;
using Cysharp.Threading.Tasks;

public class UIAttributeManagerInfo: UIScrollViewInfo{
    
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

public class UIAttributeManager: UIScrollView{
    // ---------- Config ---------- //
    public new UIAttributeManagerInfo _info {get => (UIAttributeManagerInfo)base._info; set => base._info = value; }
    UIBase owner;

    public UIAttributeManager(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_done(){
        base._init_done();
        draw_editors().Forget();
    }

    async UniTask draw_editors(){
        owner = _UISys._UIMonitor._get_UI(_info.attributes["OWNER"].get<int>());
        List<UIInfo> editors_infos = new List<UIInfo>();
        List<UIInfo> editor_infos = new();
        foreach (string key in owner._info.attributes.Keys){
            Type type = owner._info.attributes[key].get().GetType();

            if (key == "COMMAND") editor_infos = _get_editorCOMMAND(key);
            else if (type == typeof(string)) editor_infos = _get_editorString(key);
            else Debug.Log("UIAttributeManager not support type: " + key + " " + type);

            editors_infos.Add(get_title(key));
            editors_infos.AddRange(editor_infos);
            editors_infos.Add(get_separator());
        }
        editors_infos.RemoveAt(editors_infos.Count - 1);
        for(int i = 0; i < editors_infos.Count; i++){
            await _append_and_draw_item(editors_infos[i], needPlace:(i == editors_infos.Count - 1));
        }
        // return infos;
    }

    UIInfo get_title(string key){
        UIScrollTextInfo info = (UIScrollTextInfo)UIClass._set_default("UITitleText");
        info.minSize = _info.textMinSize;
        info.maxSize = _info.textMaxSize;
        info.text = key;
        return info;
    }
    
    UIInfo get_separator(){
        UIInfo info = UIClass._set_default("UISeparator");
        info.sizeDelta = _info.separatorSize;
        return info;
    }

    List<UIInfo> _get_editorString(string key){
        List<UIInfo> infos = new List<UIInfo>();
        string UI_type;

        UI_type = "UIScrollText";
        UIScrollTextInfo info_text = (UIScrollTextInfo)UIClass._set_default(UI_type);
        info_text.minSize = _info.textMinSize;
        info_text.maxSize = _info.textMaxSize;
        info_text.messageID = $"OWNER_{owner._runtimeID}_{key}";
        info_text.source = key;
        infos.Add(info_text);
        
        UI_type = "UIInputField";
        // UI_type = "UIScrollInput";
        UIInputFieldInfo info_input = (UIInputFieldInfo)UIClass._set_default(UI_type);
        // UIScrollInputInfo info_input = (UIScrollInputInfo)UIClass._set_default(UI_type);
        info_input.minSize = _info.textMinSize;
        info_input.maxSize = _info.textMaxSize;
        // info_input.sizeDelta = _info.inputTextSize;
        info_input.messageID = $"OWNER_{owner._runtimeID}_{key}";
        infos.Add(info_input);

        return infos;
    }

    List<UIInfo> _get_editorCOMMAND(string key){
        List<UIInfo> infos = new List<UIInfo>();
        string UI_type;

        string command = owner._info.attributes[key].get<string>();
        bool isFromInputSystem = command.StartsWith("FROM_INPUT");

        if (isFromInputSystem){
            infos.Add(get_title(key + "-command"));
        }

        UI_type = "UIScrollTextCommand";
        UIScrollTextInfo info_text = (UIScrollTextInfo)UIClass._set_default(UI_type);
        info_text.minSize = _info.textMinSize;
        info_text.maxSize = _info.textMaxSize;
        info_text.messageID = $"OWNER_{owner._runtimeID}_{key}";
        info_text.source = key;
        infos.Add(info_text);
        
        UI_type = "UIInputField";
        // UI_type = "UIScrollInput";
        UIInputFieldInfo info_input = (UIInputFieldInfo)UIClass._set_default(UI_type);
        // UIScrollInputInfo info_input = (UIScrollInputInfo)UIClass._set_default(UI_type);
        info_input.minSize = _info.textMinSize;
        info_input.maxSize = _info.textMaxSize;
        // info_input.sizeDelta = _info.inputTextSize;
        info_input.messageID = $"OWNER_{owner._runtimeID}_{key}";
        infos.Add(info_input);

        if (isFromInputSystem){
            string keyName = Regex.Match(command, @"--key\s+(?:""([^""]*)""|(\S+))").Groups[1].Value;
            infos.Add(get_title(key + "-trigger"));
            UI_type = "UIExecuteCommandFromAttribute";
            UIScrollTextInfo info_buttom = (UIScrollTextInfo)UIClass._set_default(UI_type);
            info_buttom.minSize = info_buttom.maxSize = _info.buttonSize;
            info_buttom.text = "isDown";
            info_buttom.attributes = new(){ { "COMMAND", $"FROM_INPUT --key \"{keyName}\" --trigger isDown" } };
            infos.Add(info_buttom.Copy());
            
            info_buttom.text = "isUp";
            info_buttom.attributes = new(){ { "COMMAND", $"FROM_INPUT --key \"{keyName}\" --trigger isUp" } };
            infos.Add(info_buttom.Copy());

            info_buttom.text = "isFirstDown";
            info_buttom.attributes = new(){ { "COMMAND", $"FROM_INPUT --key \"{keyName}\" --trigger isFirstDown" } };
            infos.Add(info_buttom.Copy());

            info_buttom.text = "isFirstUp";
            info_buttom.attributes = new(){ { "COMMAND", $"FROM_INPUT --key \"{keyName}\" --trigger isFirstUp" } };
            infos.Add(info_buttom.Copy());

        }

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
