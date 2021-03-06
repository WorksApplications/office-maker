function floorKeyValues(tenantId, floor, updateAt) {
  return [
    ["id", floor.id],
    ["version", floor.version],
    ["tenantId", tenantId],
    ["name", floor.name],
    ["ord", floor.ord],
    ["image", floor.image],
    ["flipImage", floor.flipImage ? 1 : 0],
    ["width", floor.width],
    ["height", floor.height],
    ["realWidth", floor.realWidth],
    ["realHeight", floor.realHeight],
    ["temporary", floor.temporary ? 1 : 0],
    ["updateBy", floor.updateBy],
    ["updateAt", updateAt]
  ];
}

function prototypeKeyValues(tenantId, proto) {
  return [
    ["id", proto.id],
    ["tenantId", tenantId],
    ["name", proto.name],
    ["width", proto.width],
    ["height", proto.height],
    ["backgroundColor", proto.backgroundColor],
    ["color", proto.color],
    ["fontSize", proto.fontSize],
    ["shape", proto.shape]
  ];
}

function objectKeyValues(object, updateAt) {
  return [
    ["id", object.id],
    ["name", object.name],
    ["type", object.type],
    ["x", object.x],
    ["y", object.y],
    ["width", object.width],
    ["height", object.height],
    ["backgroundColor", object.backgroundColor],
    ["fontSize", object.fontSize],
    ["color", object.color],
    ["bold", object.bold ? 1 : 0],
    ["url", object.url],
    ["shape", object.shape],
    ["personId", object.personId],
    ["floorId", object.floorId],
    ["floorVersion", object.floorVersion],
    ["updateAt", updateAt]
  ];
}

function objectOptKeyValues(object) {
  return [
    ["id", object.id],
    ["name", object.name],
    ["type", object.type],
    ["x", object.x],
    ["y", object.y],
    ["width", object.width],
    ["height", object.height],
    ["backgroundColor", object.backgroundColor],
    ["fontSize", object.fontSize],
    ["color", object.color],
    ["bold", object.bold ? 1 : 0],
    ["url", object.url],
    ["shape", object.shape],
    ["personId", object.personId],
    ["personName", object.personName || ''],
    ["personEmpNo", object.personEmpNo || ''],
    ["personPost", object.personPost || ''],
    ["personTel1", object.personTel1 || ''],
    ["personTel2", object.personTel2 || ''],
    ["personMail", object.personMail || ''],
    ["personImage", object.personImage || ''],
    ["floorId", object.floorId],
    ["editing", object.editing ? 1 : 0],
    ["updateAt", object.updateAt]
  ];
}


function colorKeyValues(tenantId, c) {
  return [
    ["id", c.id],
    ["tenantId", tenantId],
    ["ord", c.ord],
    ["type", c.type],
    ["color", c.color]
  ];
}

module.exports = {
  floorKeyValues: floorKeyValues,
  prototypeKeyValues: prototypeKeyValues,
  objectKeyValues: objectKeyValues,
  objectOptKeyValues: objectOptKeyValues,
  colorKeyValues: colorKeyValues
};
