using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;

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
        
    }

    void onSubmit(string _) => _Event._action_submit(new(EventSystem.current), false);

    public override void _update_info(){
        base._update_info();
        if (_info is UIInputFieldInfo info){
        }
    }
}
