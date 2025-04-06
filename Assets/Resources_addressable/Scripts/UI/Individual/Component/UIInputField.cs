using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Cysharp.Threading.Tasks;

public class UIInputFieldInfo: UIInfo{
}

public class UIInputField: UIBase{
    // ---------- Public ---------- //

    // ---------- Child ---------- //
    GameObject TextArea;
    GameObject Placeholder;
    GameObject Text;
    TMP_InputField inputField;
    // ---------- Status ---------- //
    public string _text { get => inputField.text; set => inputField.text = value; }
    // ---------- Config ---------- //
    public new UIInputFieldInfo _info {get => (UIInputFieldInfo)base._info; set => base._info = value; }


    public UIInputField(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_begin(){
        TextArea = _self.transform.Find("Text Area").gameObject;
        Placeholder = TextArea.transform.Find("Placeholder").gameObject;
        Text = TextArea.transform.Find("Text").gameObject;
        inputField = _self.GetComponent<TMP_InputField>();
        inputField.onSubmit.AddListener(onSubmit);
        inputField.onEndEdit.AddListener(onEditEnd);
        inputField.onSelect.AddListener(onSelect);
        inputField.textComponent.font = _MatSys._font._get_fontTMP("fusion_pixel");
    }

    void onSelect(string _){
        InputSystem._onEdit = true;
    }
    void onEditEnd(string _){
        InputSystem._onEdit = false;
    }
    async UniTaskVoid remove_focus_and_return(){
        await UniTask.DelayFrame(1);
        inputField.interactable = false;  
        inputField.interactable = true;   
        EventSystem.current.SetSelectedGameObject(_self);
    }
    void onSubmit(string _) {
        remove_focus_and_return().Forget();
        _Event._action_submit(new(EventSystem.current), false);
    }



    public override void _update_info(){
        base._update_info();
        if (_info is UIInputFieldInfo info){
        }
    }
}
