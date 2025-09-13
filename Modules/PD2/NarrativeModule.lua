NarrativeModule = NarrativeModule or BeardLib:ModuleClass("narrative", ItemModuleBase)
NarrativeModule._loose = true

BeardLib:RegisterModule("Narrative", NarrativeModule)

local TEXTURE = Idstring("texture")

function NarrativeModule:init(...)
    self.clean_table = table.add(clone(self.clean_table), {
        {param = "chain", action = {"number_indexes", "remove_metas"}},
        {
            param = "chain",
            action = function(tbl)
                for _, v in pairs(tbl) do
                    if v.level_id then
                        v = BeardLib.Utils:RemoveAllNumberIndexes(v, true)
                    else
                        for _, _v in pairs(v) do
                            _v = BeardLib.Utils:RemoveAllNumberIndexes(_v, true)
                        end
                    end
                end
            end},
        {param = "crimenet_callouts", action = "number_indexes"},
        {param = "crimenet_videos", action = "number_indexes"},
        {param = "payout", action = "number_indexes"},
        {param = "contract_cost", action = "number_indexes"},
        {param = "experience_mul", action = "number_indexes"},
        {param = "allowed_gamemodes", action = "number_indexes"}
    })
    return NarrativeModule.super.init(self, ...)
end

function NarrativeModule:AddNarrativeData(narr_self, tweak_data)
    local id = self._config.id

    local data = clone(self._config)
    table.merge(data, {
        name_id = data.name_id or ("heist_" .. data.id .. "_name"),
        briefing_id = data.brief_id or ("heist_" .. data.id .. "_brief"),
        contact = data.contact or "custom",
        jc = math.max(data.jc, 10) or 50,
        payout = data.payout or {0.001,0.001,0.001,0.001,0.001},
        contract_cost = data.contract_cost or {0.001,0.001,0.001,0.001,0.001},
        experience_mul = data.experience_mul or {0.001,0.001,0.001,0.001,0.001},
        ignore_heat = NotNil(data.ignore_heat, true),
        mod_path = self._mod.ModPath,
        custom = true
    })

    if self._config.merge_data then
        table.merge(data, BeardLib.Utils:RemoveMetas(self._config.merge_data, true))
    end

    narr_self.jobs[tostring(self._config.id)] = data

    local id = tostring(self._config.id)
    if not data.hide_from_crimenet and ((data.job_wrapper and #data.job_wrapper > 0) or #data.chain > 0) and not table.contains(narr_self._jobs_index, id) then
        table.insert(narr_self._jobs_index, id)
    end
end

function NarrativeModule:RegisterHook()
    if tweak_data and tweak_data.narrative then
        self:AddNarrativeData(tweak_data.narrative, tweak_data)
        tweak_data.narrative:set_job_wrappers()
    else
        Hooks:PostHook(NarrativeTweakData, "init", self._config.id .. "AddNarrativeData", ClassClbk(self, "AddNarrativeData"))
    end
end