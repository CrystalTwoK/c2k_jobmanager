let jobs = {}
let bodySubContainer = document.querySelector('.body-sub-container-2');
let currentSection = 'lista_lavori';

let selectedJobID = "";
let selectedJobData = {};

$(document).ready(() => {

    window.addEventListener('message', (e)=>{
        let data = e.data
        if (data.type == 'openMenu'){
            updateJobs(data.jobs);
            $(document.body).removeClass('hidden');
            listJobs();
        } else if (data.type == 'updateJobs') {
            resetTable();

            updateJobs(data.jobs);

            console.log('jobs updated');

            listJobs();

            refreshGradi();

        }
    })

    function updateJobs(newJobs){
        newJobs.sort(function(a, b) {
            var textA = a.label.toLowerCase();
            var textB = b.label.toLowerCase();
            return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
        });
        console.log(JSON.stringify(newJobs));
        jobs = newJobs;
    }

    function listJobs(){
        for (let i = 0; i < jobs.length; i++){
            let newRow = document.createElement('div');
            $(newRow).addClass('text-white');
            $(newRow).addClass('row');
            if (i % 2 == 0) { $(newRow).addClass('pari');}
            let newLineIDElement = document.createElement('div');
            let newJobNameElement = document.createElement('div');
            let newJobIDElement = document.createElement('div');
            let newJobGradesElement = document.createElement('div');
            let newJobButtonElement = document.createElement('div');
            let newButtonElement = document.createElement('button');
            $(newLineIDElement).addClass('col-1');
            $(newLineIDElement).addClass('text-center');
            $(newLineIDElement).addClass('id');
            $(newJobNameElement).addClass('col');
            $(newJobIDElement).addClass('col');
            $(newJobGradesElement).addClass('col');
            $(newJobButtonElement).addClass('col');
            $(newJobButtonElement).addClass('text-end');
            $(newButtonElement).addClass('btn');
            $(newButtonElement).addClass('btn-danger');
            $(newButtonElement).addClass('modifica-lavoro');
            newButtonElement.id = jobs[i].id;
            $(newRow).append(newLineIDElement);
            $(newRow).append(newJobNameElement);
            $(newRow).append(newJobIDElement);
            $(newRow).append(newJobGradesElement);
            $(newJobButtonElement).append(newButtonElement);
            $(newRow).append(newJobButtonElement);
            $(bodySubContainer).append(newRow);

            newLineIDElement.innerHTML = `${i}`;
            newJobNameElement.innerHTML = `${jobs[i].label}`;
            newJobIDElement.innerHTML = `${jobs[i].id}`;
            newJobGradesElement.innerHTML = `${Object.keys(jobs[i].grades).length}`;
            newButtonElement.innerHTML = `Modifica`;
        }
    }

    window.addEventListener('keydown', (e)=>{
        // if (e.key == "Escape"){
        //     e.preventDefault();
        //     resetTable();
        //     resetGradi();
        //     closeMenu();
        // }
    })

    $('.esci').on('click', (e)=>{
        closeMenu()
    })

    function closeMenu(){
        resetJobs();
        resetTable();
        resetGradi();
        hideModals();
        $(document.body).addClass('hidden');
        $.post('https://c2k_jobmanager/closeMenu');
    }

    function resetJobs(){
        jobs = {}
    }

    function hideModals(){
        $('#modalModificaLavoro').modal('hide');
        $('#modalAggiungiLavoro').modal('hide');
    }

    $('#AggiungiLavoro').on('click', (e)=>{

        let newJobName = document.querySelector('#newJobName')
        let newJobID = document.querySelector('#newJobID')

        if (newJobName.value == "") { newJobName.classList.add('is-invalid')}

        if (newJobID.value == "") { newJobID.classList.add('is-invalid')}
        
        $.post('https://c2k_jobmanager/addJob', JSON.stringify({
            newJobName: newJobName.value,
            newJobID: newJobID.value
        }));

        newJobName.value = "";
        newJobID.value = ""
    })

    $('#chiudiModificaLavoro').on('click', (e) =>{
        resetGradi();
    })

    $('#closeModificaLavoro').on('click', (e) =>{
        resetGradi();
    })

    $('#ModificaLavoro').on('click', (e) =>{

        let grades = document.querySelectorAll('.grade-element');

        console.log('modifica lavoro premuto -----------------------------');
        console.log("grades.length: "+ JSON.stringify(grades));
        
        for (let i = 0; i < grades.length; i++){
            // console.log(JSON.stringify(grades[i].id))
            console.log('inside for loop n: '+  i);
            console.log(grades[i].id)
            let gradeIdx = grades[i].id[selectedJobID.length];
            let sGradeIdx = gradeIdx.toString();
            if (grades[i].id == `${selectedJobID + gradeIdx}name`){
                selectedJobData.grades[gradeIdx.toString()].name = grades[i].value;
                console.log(selectedJobData.grades[gradeIdx.toString()].name + " modificato in " + grades[i].value)
            } else if (grades[i].id == `${selectedJobID + gradeIdx}payment`){
                selectedJobData.grades[gradeIdx.toString()].payment = parseInt(grades[i].value);
                console.log(selectedJobData.grades[gradeIdx.toString()].payment + " modificato in " + grades[i].value)
            } else if (grades[i].id == `${selectedJobID + gradeIdx}isboss`){
                selectedJobData.grades[gradeIdx.toString()].isboss = grades[i].value;
                console.log(selectedJobData.grades[gradeIdx.toString()].isboss + " modificato in " + grades[i].value)
            }
        }

        console.log("BELANDI " + JSON.stringify(selectedJobData.grades))

        let jobName = document.querySelector('#jobName');

        selectedJobData.label = jobName.value;
        console.log("selectedJobData.label: " + JSON.stringify(selectedJobData.label));
        console.log("jobName.value: " + JSON.stringify(jobName.value));
        // selectedJobData.id = jobID.value;
        // console.log("selectedJobData.id: " + JSON.stringify(selectedJobData.id));

        // console.log(JSON.stringify(selectedJobData.grades))

        $.post('https://c2k_jobmanager/updateJob', JSON.stringify({
            selectedJobID: selectedJobID,
            newJobData: selectedJobData,
        }));

        
        $('#modalModificaLavoro').modal('hide');
        resetGradi();
        selectedJobData = {};
        selectedJobID = "";
    })

    window.addEventListener('click', (e) =>{
        if (e.target.classList.contains('modifica-lavoro')){
            selectedJobID = e.target.id;
            selectedJobData = {}

            for (let i = 0; i < jobs.length; i++) {
                if (jobs[i].id == selectedJobID) {
                    selectedJobData = jobs[i]
                    break;
                }
            }

            // console.log(JSON.stringify(selectedJobData))

            $('#modalModificaLavoro').modal('show');

            $('#jobName').attr('value', selectedJobData.label)
            $('#jobID').attr('value', selectedJobID)


            if (selectedJobData.grades){

                console.log('PAPERE ' + JSON.stringify(selectedJobData.grades));

                let modalBody = document.querySelector('.modal-body-modifica-lavoro');

                modalBody.innerHTML +=`
                <div class="input-group">
                <span class="input-group-text">#</span>
                <input type="text" aria-label="First name" class="form-control" value="Nome" disabled>
                <input type="text" aria-label="Last name" class="form-control" value="Stipendio" disabled>
                <input type="text" aria-label="Last name" class="form-control" value="Boss" disabled>
                <button class="btn btn-sm btn-dark text-dark" type="button" disabled>< ELIMINA</button>
                </div>`

                for (let i = 0; i <= Object.keys(selectedJobData.grades).pop(); i++){
                    // console.log('inside for')
    
                    if (selectedJobData.grades[i] == undefined && selectedJobData.grades[i + 1] != undefined) {
                        selectedJobData.grades[i] = selectedJobData.grades[i + 1];
                         delete selectedJobData.grades[i + 1];
                    }
    
                    if (selectedJobData.grades[i].name == undefined) { selectedJobData.grades[i].name = ""}
                    if (selectedJobData.grades[i].payment == undefined) { selectedJobData.grades[i].payment = ""}
                    if (selectedJobData.grades[i].isboss == undefined) { selectedJobData.grades[i].isboss = false}
    
                    // console.log(selectedJobData.grades[i].name)
    
                    modalBody.innerHTML = modalBody.innerHTML + `
                    <div class="input-group flex-nowrap">
                        <span class="input-group-text" id="${selectedJobID + i}id">${i}</span>
                        <input type="text" id="${selectedJobID + i}name" class="form-control grade-element" aria-describedby="${selectedJobID + i}id" value="${selectedJobData.grades[i].name}">
                        <input type="text" id="${selectedJobID + i}payment" class="form-control grade-element" value="${selectedJobData.grades[i].payment}">
                        <input type="text" id="${selectedJobID + i}isboss" class="form-control grade-element" value="${String(selectedJobData.grades[i].isboss)}">
                        <button id="${selectedJobID + i}" class="btn btn-sm btn-dark grade-delete" type="button">< ELIMINA</button>
                    </div>
                    `
                }
            
                modalBody.innerHTML += `
                <div class="d-grid gap-2 mt-2">
                <button id="aggiungi-grado" class="btn btn-outline-primary" type="button">AGGINGI UN GRADO</button>
                </div>`;

                modalBody.innerHTML += `<br>
                <hr>
                <div class="d-grid gap-2">
                <button id="elimina-lavoro" class="btn btn-outline-danger" type="button">ELIMINA LAVORO</button>
                </div>`;

            }
        }

        if (e.target.id == 'aggiungi-grado'){
            let newGrade = {
                name: "",
                payment: "",
                isboss: false
            }
            // selectedJobData.grades.push(newGrade);
            selectedJobData.grades[Object.keys(selectedJobData.grades).length] = newGrade;
            // console.log(JSON.stringify(newGrade))
            // console.log(JSON.stringify(Object.keys(selectedJobData.grades).length))
            // console.log('aggiungi grado pressed')
            refreshGradi()
        }

        if (e.target.id == 'elimina-lavoro'){
            $('#modalModificaLavoro').modal('hide');
            resetGradi();
            $.post('https://c2k_jobmanager/deleteJob', JSON.stringify({
                jobToDelete: selectedJobID
            }))
            console.log('lavoro '+selectedJobID+" eliminato!");
        }

        if (e.target.classList.contains('grade-delete')){
            let grades = document.querySelectorAll('.grade-element');

            let deleteIdx = e.target.id[selectedJobID.length];

            for (let i = 0; i < grades.length; i++){
                let gradeIdx = grades[i].id[selectedJobID.length];
                
                if (deleteIdx == gradeIdx){
                    grades[i].parentElement.remove();
                    console.log(`[${gradeIdx}]${selectedJobData.grades[gradeIdx].name} ELIMINATO`)
                    delete selectedJobData.grades[gradeIdx];
                    console.log('NEW SELECTED JOB DATA: ' + JSON.stringify(selectedJobData.grades))
                    refreshGradi();
                    break;
                }

            }


        }
    })

    function resetTable(){
        while (bodySubContainer.childNodes.length > 2) {
            bodySubContainer.removeChild(bodySubContainer.lastChild);
        }
    }

    function resetGradi(){
        let modalBody = document.querySelector('.modal-body-modifica-lavoro');
        while (modalBody.childNodes.length > 4) {
            modalBody.removeChild(modalBody.lastChild);
        }
    }

    function refreshGradi(){  

        if (selectedJobData.grades){

            resetGradi();

            let modalBody = document.querySelector('.modal-body-modifica-lavoro');

            modalBody.innerHTML +=`
                <div class="input-group">
                <span class="input-group-text">#</span>
                <input type="text" aria-label="First name" class="form-control" value="Nome" disabled>
                <input type="text" aria-label="Last name" class="form-control" value="Stipendio" disabled>
                <input type="text" aria-label="Last name" class="form-control" value="Boss" disabled>
                <button class="btn btn-sm btn-dark text-dark" type="button" disabled>< ELIMINA</button>
                </div>`

            for (let i = 0; i <= Object.keys(selectedJobData.grades).pop(); i++){
                console.log('inside for')

                if (selectedJobData.grades[i] == undefined && selectedJobData.grades[i + 1] != undefined) {
                    selectedJobData.grades[i] = selectedJobData.grades[i + 1];
                     delete selectedJobData.grades[i + 1];
                }

                if (selectedJobData.grades[i].name == undefined) { selectedJobData.grades[i].name = ""}
                if (selectedJobData.grades[i].payment == undefined) { selectedJobData.grades[i].payment = ""}
                if (selectedJobData.grades[i].isboss == undefined) { selectedJobData.grades[i].isboss = false}

                // console.log(selectedJobData.grades[i].name)

                modalBody.innerHTML = modalBody.innerHTML + `
                <div class="input-group flex-nowrap">
                    <span class="input-group-text" id="${selectedJobID + i}id">${i}</span>
                    <input type="text" id="${selectedJobID + i}name" class="form-control grade-element" aria-describedby="${selectedJobID + i}id" value="${selectedJobData.grades[i].name}">
                    <input type="text" id="${selectedJobID + i}payment" class="form-control grade-element" value="${selectedJobData.grades[i].payment}">
                    <input type="text" id="${selectedJobID + i}isboss" class="form-control grade-element" value="${String(selectedJobData.grades[i].isboss)}">
                    <button id="${selectedJobID + i}" class="btn btn-sm btn-dark grade-delete" type="button">< ELIMINA</button>
                </div>
                `
            }
        
            modalBody.innerHTML += `
            <div class="d-grid gap-2 mt-2">
            <button id="aggiungi-grado" class="btn btn-outline-primary" type="button">AGGINGI UN GRADO</button>
            </div>`;

            modalBody.innerHTML += `<br>
            <hr>
            <div class="d-grid gap-2">
            <button id="elimina-lavoro" class="btn btn-outline-danger" type="button">ELIMINA LAVORO</button>
            </div>`;

        }
    }

})