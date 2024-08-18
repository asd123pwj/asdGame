// using TMPro;
// using UnityEngine;
// using UnityEngine.UI;
// using System.Collections.Generic;

// public class UISystemTmp : MonoBehaviour{
//     HierarchySearch _hierarchy_search;
//     InputSystem _input_base;
//     GameConfigs _game_configs;
//     // ----------
//     TMP_Text _text;
//     Button _button;
//     TMP_InputField _input_field;
//     Toggle _toggle;
//     Slider _slider;
//     ScrollRect _scroll_view;
//     TMP_Dropdown _dropdown;

//     // Transform _character;
//     TilemapSystem _tilemap_system;
//     // ---------- status
//     bool _isInit = true;

//     void Start(){
//         _hierarchy_search = GameObject.Find("System").GetComponent<HierarchySearch>();
//         _game_configs = _hierarchy_search._searchInit<GameConfigs>("System");
//         _input_base = _hierarchy_search._searchInit<InputSystem>("Input");
//         _tilemap_system = _hierarchy_search._searchInit<TilemapSystem>("Tilemap");
        
//         // _character = GameObject.FindGameObjectWithTag("Player").transform; 
//         // _tilemap_system = GameObject.FindGameObjectWithTag("Tilemap").GetComponent<TilemapSystem>();

//     }

//     void Update(){
//         if (_isInit) { 
//             _init_button_event(); 
//             _isInit = false; 
//         } 
//         // if (_character != null && _text != null){
//         //     Vector3 screen_pos = Camera.main.WorldToScreenPoint(_character.position);
//         //     screen_pos.y += 2f;
//         //     Vector3Int map_xy = _tilemap_system._mapping_worldXY_to_mapXY(_character.position, _tilemap_system._tilemap_modify);
//         //     _text.text = $"({map_xy.x}, {map_xy.y})";
//         //     // positionText.rectTransform.position = screen_pos;
//         // }
//     }

//     void _init_button_event(){
//         _text = _hierarchy_search._searchInit<TMP_Text>("UI", "Text (TMP)");
//         _button = _hierarchy_search._searchInit<Button>("UI", "Button");
//         _input_field = _hierarchy_search._searchInit<TMP_InputField>("UI", "InputField (TMP)");
//         _toggle = _hierarchy_search._searchInit<Toggle>("UI", "Toggle");
//         _slider = _hierarchy_search._searchInit<Slider>("UI", "Slider");
//         _scroll_view = _hierarchy_search._searchInit<ScrollRect>("UI", "Scroll View");
//         _dropdown = _hierarchy_search._searchInit<TMP_Dropdown>("UI", "Dropdown");
//         _dropdown.options = new List<TMP_Dropdown.OptionData>{new ("mwhls.top"), new ("panwj.top")};
//         // _dropdown.ClearOptions();
//         // _dropdown.AddOptions(new List<TMP_Dropdown.OptionData>{new ("mwhls.top"), new ("panwj.top")});
//         _dropdown.onValueChanged.AddListener(_on_dropdown_changed);
//         _button.onClick.AddListener(_on_button_click);
//         _toggle.onValueChanged.AddListener(_on_toggle_changed);
//         _slider.onValueChanged.AddListener(_on_slider_changed);
//     }

//     void _on_button_click(){
//         _scroll_view.GetComponentInChildren<TMP_Text>().text = _input_field.text;
//         Debug.Log(_input_field.text);
//     }

//     void _on_toggle_changed(bool isOn){
//         Debug.Log(_toggle.isOn);
//     }

//     void _on_slider_changed(float value){
//         Debug.Log(_slider.value);
//     }

//     void _on_dropdown_changed(int index){
//         Debug.Log(_dropdown.options[index].text);
//     }

//     public void _update_scrollView(string text){
//         _scroll_view.GetComponentInChildren<TMP_Text>().text = text;
//     }
// }
