local bodyPlanLoader = {}

local extensionSearchPaths = {
  'asset/body_plan_extensions/%s.json',
}

local function readJson(path)
  local contents, err = lovr.filesystem.read(path)
  if not contents then
    error('Failed to read ' .. path .. ': ' .. tostring(err))
  end
  return lovr.json.decode(contents)
end

local function vec3FromArray(array)
  return vector(array[1] or 0, array[2] or 0, array[3] or 0)
end

local function inferReferenceKind(name)
  if name == 'origin' then
    return 'origin'
  end
  if name:match('^slot_') then
    return 'slot'
  end
  return 'joint'
end

local function mergeReferences(baseReferences, overrides)
  local merged = {}
  for name, position in pairs(baseReferences or {}) do
    merged[name] = vec3FromArray(position)
  end
  for name, position in pairs(overrides or {}) do
    merged[name] = vec3FromArray(position)
  end
  return merged
end

local function resolveExtensionPath(extensionId, overridePath)
  if overridePath then
    return overridePath
  end
  return string.format(extensionSearchPaths[1], extensionId)
end

local function copyPartDefinition(partId, partData, mappingPart)
  local mappingPartData = mappingPart or {}
  local references = mergeReferences(
    partData.references,
    mappingPartData.reference_overrides
  )

  return {
    id = partId,
    vital = partData.vital,
    references = references,
    children = partData.children or {},
    visual = mappingPartData.visual,
    extensionRoot = false,
    attach = nil,
  }
end

local function mergeExtensionParts(partsRegistry, extensionData, mappingParts)
  for partId, partData in pairs(extensionData.parts) do
    if partsRegistry[partId] then
      print('Warning: extension part "' .. partId .. '" overrides existing part')
    end
    partsRegistry[partId] = copyPartDefinition(partId, partData, mappingParts and mappingParts[partId])
  end

  local rootPart = partsRegistry[extensionData.root]
  if rootPart then
    rootPart.extensionRoot = true
    rootPart.attach = {
      part = extensionData.attach.part,
      reference = extensionData.attach.reference,
    }
  else
    print('Warning: extension root part "' .. tostring(extensionData.root) .. '" not found')
  end
end

function bodyPlanLoader.loadCharacterMapping(mappingPath)
  local mapping = readJson(mappingPath)
  local plan = readJson(mapping.body_plan)

  local mappingExtensions = mapping.extensions or {}
  local disabledExtensions = {}
  for _, extensionId in ipairs(mappingExtensions.disable or {}) do
    disabledExtensions[extensionId] = true
  end

  local extensionOverrides = mappingExtensions.overrides or {}
  local partsRegistry = {}

  for partId, partData in pairs(plan.parts) do
    partsRegistry[partId] = copyPartDefinition(partId, partData, mapping.parts and mapping.parts[partId])
  end

  local resolvedExtensions = {}
  for _, extensionId in ipairs(plan.extensions or {}) do
    if not disabledExtensions[extensionId] then
      local extensionPath = resolveExtensionPath(extensionId, extensionOverrides[extensionId])
      local extensionData = readJson(extensionPath)
      mergeExtensionParts(partsRegistry, extensionData, mapping.parts)
      table.insert(resolvedExtensions, extensionData.id)
    end
  end

  return {
    mapping = mapping,
    plan = plan,
    root = plan.root,
    parts = partsRegistry,
    extensions = resolvedExtensions,
  }
end

return bodyPlanLoader
