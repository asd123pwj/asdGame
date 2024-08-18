// public static T InheritStruct<T>(T baseStruct, T newStruct) where T : struct{
//     Type type = typeof(T);
//     foreach (var field in type.GetFields()){
//         var baseValue = field.GetValue(baseStruct);
//         var newValue = field.GetValue(newStruct);
//         if (newValue == null || newValue.Equals(Activator.CreateInstance(field.FieldType))){
//             field.SetValue(newStruct, baseValue);
//         }
//     }
//     return newStruct;
// }