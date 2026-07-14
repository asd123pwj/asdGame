class_name BehaviorDependence
extends RefCounted


var name: String
var attr_names: Array[String]
var attr_thres: Array[int]
var attr_match: Array[String]


func _init(name: String, attr_names: Array[String], attr_thres: Array[int], attr_match: Array[String]) -> void:
    self.name = name
    self.attr_names = attr_names
    self.attr_thres = attr_thres
    self.attr_match = attr_match

func listen(char_: Character) -> void:
    for i in range(attr_names.size()):
        pass


# static func can_execute() -> bool:
