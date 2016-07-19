
function userKeyValues(user) {
  return [
    ["id", user.id],
    ["pass", user.pass],
    ["role", user.role],
    ["personId", user.personId],
  ];
}
function personKeyValues(person) {
  return [
    ["id", person.id],
    ["name", person.name],
    ["org", person.org],
    ["tel", person.tel],
    ["mail", person.mail],
    ["image", person.image]
  ];
}
function floorKeyValues(floor) {
  return [
    ["id", floor.id],
    ["version", floor.version || 0],//TODO
    ["name", floor.name],
    ["ord", floor.order || 0],
    ["image", floor.image],
    ["width", floor.width],
    ["height", floor.height],
    ["realWidth", floor.realWidth],
    ["realHeight", floor.realHeight],
    ["public", floor.public],
    ["updateBy", floor.updateBy],
    ["updateAt", floor.updateAt]
  ];
}
function prototypeKeyValues(proto) {
  return [
    ["id", proto.id],
    ["name", proto.name],
    ["width", proto.width],
    ["height", proto.height],
    ["color", proto.color]
  ];
}
function equipmentKeyValues(floorId, floorVersion, equipment) {
  return [
    ["id", equipment.id],
    ["name", equipment.name],
    ["x", equipment.x],
    ["y", equipment.y],
    ["width", equipment.width],
    ["height", equipment.height],
    ["color", equipment.color],
    ["personId", equipment.personId],
    ["floorId", floorId],
    ["floorVersion", floorVersion]
  ];
}

module.exports = {
  userKeyValues: userKeyValues,
  personKeyValues: personKeyValues,
  floorKeyValues: floorKeyValues,
  prototypeKeyValues: prototypeKeyValues,
  equipmentKeyValues: equipmentKeyValues
};
