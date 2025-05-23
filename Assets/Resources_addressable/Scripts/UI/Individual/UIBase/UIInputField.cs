using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Cysharp.Threading.Tasks;
using Newtonsoft.Json;

public class UIInputFieldInfo: UIInfo{
    [JsonProperty("fontSize", NullValueHandling = NullValueHandling.Ignore)]
    private int? _fontSize;
    private int _fontSize_default => 20;
    [JsonIgnore] public int fontSize { get => _fontSize ?? _fontSize_default; set => _fontSize = value; }

    [JsonProperty("font", NullValueHandling = NullValueHandling.Ignore)]
    private string _font;
    private string _font_default => "fusion_pixel_12px_zh_hans";
    [JsonIgnore] public string font { get => _font ?? _font_default; set => _font = value; }
    
    [JsonProperty("placeholder", NullValueHandling = NullValueHandling.Ignore)]
    private string _placeholder;
    private string _placeholder_default => "输入...";
    [JsonIgnore] public string placeholder { get => _placeholder ?? _placeholder_default; set => _placeholder = value; }
    
    [JsonProperty("marginTop", NullValueHandling = NullValueHandling.Ignore)] 
    private int? _marginTop;
    private int _marginTop_default => 4;
    [JsonIgnore] public int marginTop { get => _marginTop ?? _marginTop_default; set => _marginTop = value; }

    [JsonProperty("marginBottom", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginBottom;
    private int _marginBottom_default => 6;
    [JsonIgnore] public int marginBottom { get => _marginBottom ?? _marginBottom_default; set => _marginBottom = value; }

    [JsonProperty("marginLeft", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginLeft;
    private int _marginLeft_default => 12;
    [JsonIgnore] public int marginLeft { get => _marginLeft ?? _marginLeft_default; set => _marginLeft = value; }

    [JsonProperty("marginRight", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginRight;
    private int _marginRight_default => 12;
    [JsonIgnore] public int marginRight { get => _marginRight ?? _marginRight_default; set => _marginRight = value; }

    [JsonProperty("maxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _maxSize;
    private Vector2 _maxSize_default { get => new (640, 640); }
    [JsonIgnore] public Vector2 maxSize { get => _maxSize ?? _maxSize_default; set => _maxSize = value; }

    [JsonProperty("minSize", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _minSize;
    private Vector2 _minSize_default { get => new (64, 64); }
    [JsonIgnore] public Vector2 minSize { get => _minSize ?? _minSize_default; set => _minSize = value; }

}

public class UIInputField: UIBase{
    // ---------- Public ---------- //

    // ---------- Child ---------- //
    GameObject TextArea;
    GameObject Placeholder;
    GameObject Text;
    TMP_InputField inputField;
    TextMeshProUGUI TMPText_placeholder;
    // ---------- Status ---------- //
    public string _text { get => inputField.text; set => inputField.text = value; }
    // ---------- Config ---------- //
    public new UIInputFieldInfo _info {get => (UIInputFieldInfo)base._info; set => base._info = value; }


    public UIInputField(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_begin(){
        init_child();
        init_input_action();
        init_TMPText();
    }

    public override void _apply_UIShape(){
        base._apply_UIShape();
        adaptive_resize();
    }
    
    void adaptive_resize(){
        _rt_self.sizeDelta = new Vector2(
            Mathf.Clamp(inputField.preferredWidth, _info.minSize.x, _info.maxSize.x),
            Mathf.Clamp(inputField.preferredHeight, _info.minSize.y, _info.maxSize.y)
        );
    }

    void init_child(){
        TextArea = _self.transform.Find("Text Area").gameObject;
        Placeholder = TextArea.transform.Find("Placeholder").gameObject;
        Text = TextArea.transform.Find("Text").gameObject;
        inputField = _self.GetComponent<TMP_InputField>();
        TMPText_placeholder = Placeholder.GetComponent<TextMeshProUGUI>();
    }

    void init_input_action(){
        inputField.onSubmit.AddListener(onSubmit);
        inputField.onEndEdit.AddListener(onEditEnd);
        inputField.onSelect.AddListener(onSelect);
        inputField.onValueChanged.AddListener(onValueChange);
    }

    void init_TMPText(){
        inputField.textComponent.font = _MatSys._font._get_fontTMP(_info.font);
        inputField.textComponent.fontSize = _info.fontSize;
        inputField.textComponent.margin = new(_info.marginLeft, _info.marginTop, _info.marginRight, _info.marginBottom);
        TMPText_placeholder.font = _MatSys._font._get_fontTMP(_info.font);
        TMPText_placeholder.fontSize = _info.fontSize;
        TMPText_placeholder.margin = new(_info.marginLeft, _info.marginTop, _info.marginRight, _info.marginBottom);
        TMPText_placeholder.text = _info.placeholder;
        adaptive_resize();
    }


    void onValueChange(string _){
        adaptive_resize();
    }
    void onSelect(string _){
        InputSystem._onEdit = true;
    }
    void onEditEnd(string _){
        Debug.Log("onEditEnd");
        InputSystem._onEdit = false;
    }
    async UniTaskVoid remove_focus_and_return(){
        await UniTask.DelayFrame(1);
        inputField.interactable = false;  
        inputField.interactable = true;   
        EventSystem.current.SetSelectedGameObject(_self);
    }
    void onSubmit(string _) {
        if (InputSystem._keyStatus["left shift"].isDown || InputSystem._keyStatus["right shift"].isDown){
            return;
        }
        remove_focus_and_return().Forget();
        _Event._action_submit(new(EventSystem.current), false);
    }



    public override void _update_info(){
        base._update_info();
        if (_info is UIInputFieldInfo info){
        }
    }
}
