using System;
using Newtonsoft.Json;
using UnityEngine;
using Newtonsoft.Json.Linq;

public class Vector2Converter: JsonConverter<Vector2?>{
    public override void WriteJson(JsonWriter writer, Vector2? value, JsonSerializer serializer){
        if (value.HasValue){
            writer.WriteStartObject();
            writer.WritePropertyName("x");
            writer.WriteValue(value.Value.x);
            writer.WritePropertyName("y");
            writer.WriteValue(value.Value.y);
            writer.WriteEndObject();
        }
        else{
            writer.WriteNull();
        }
    }

    public override Vector2? ReadJson(JsonReader reader, Type objectType, Vector2? existingValue, bool hasExistingValue, JsonSerializer serializer){
        return JsonConvert.DeserializeObject<Vector2>(serializer.Deserialize(reader).ToString());
    }
}

public class UIInfoConverter : JsonConverter{
    public override bool CanConvert(Type objectType){
        return objectType == typeof(UIInfo);
    }

    public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer){
        JObject jo = JObject.Load(reader);

        if (jo["info_type"] != null){
            string typeName = jo["info_type"].ToString();
            Type type = Type.GetType(typeName);
            if (type != null && typeof(UIInfo).IsAssignableFrom(type)){
                return jo.ToObject(type, serializer);
            }
        }

        return jo.ToObject<UIInfo>(serializer);
    }

    public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer){
        throw new NotImplementedException();
    }
}
