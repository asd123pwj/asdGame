// using UnityEngine;
// using UnityEngine.EventSystems;
// using TMPro;
// using Newtonsoft.Json;
// using UnityEngine.UI;
// using Cysharp.Threading.Tasks;

// public class UIAttributeManagerInfo: UIScrollViewInfo{
    
// }

// public class UIAttributeManager: UIScrollView{
//     // ---------- Public ---------- //

//     // ---------- Child ---------- //
//     TextMeshProUGUI TMP_Text;
//     ScrollRect ScrollRect;
//     GameObject Viewport;
//     GameObject Content;
//     GameObject Scrollbar_Horizontal;
//     GameObject Scrollbar_Vertical;
//     GameObject Text;
//     // ---------- Status ---------- //
//     public string _text { get => TMP_Text.text; set => TMP_Text.text = value; }
//     // ---------- Config ---------- //
//     public new UIAttributeManagerInfo _info {get => (UIAttributeManagerInfo)base._info; set => base._info = value; }


//     public UIAttributeManager(GameObject parent, UIInfo info): base(parent, info){
//     }

//     public override void _init_begin(){
//         Viewport = _self.transform.Find("Viewport").gameObject;
//         Content = Viewport.transform.Find("Content").gameObject;
//         Scrollbar_Horizontal = _self.transform.Find("Scrollbar Horizontal").gameObject;
//         Scrollbar_Vertical = _self.transform.Find("Scrollbar Vertical").gameObject;
//         Text = Content.transform.Find("Text").gameObject;
//         TMP_Text = Text.GetComponent<TextMeshProUGUI>();
//         ScrollRect = _self.GetComponent<ScrollRect>();
//         // Text = _self.GetComponent<TextMeshProUGUI>() ?? _self.AddComponent<TextMeshProUGUI>();
//         // if (_info is UIScrollTextInfo info){
//         //     TMP_Text.color = info.color;
//         // }
        
//     }

//     public override void _init_done(){
//         Debug.Log(_attributes["RIGHT_MENU_OWNER"]);
//         if (_info is UIAttributeManagerInfo info){
//         }
//     }
//     async UniTaskVoid move_buttom(){
//         await UniTask.Delay(10);
//         ScrollRect.normalizedPosition = Vector2.zero;
//     }

//     // void onSubmit(string _) => _Event._action_submit(new(EventSystem.current), false);

//     public override void _update_info(){
//         base._update_info();
//         if (_info is UIAttributeManagerInfo info){
//         }
//     }
// }
