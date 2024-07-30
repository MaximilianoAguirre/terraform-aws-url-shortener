const getURLs = () => {
    axios
        .get(config.base_url + "/url")
        .then((response) => {
            const urls = response.data;

            let table_content = document.getElementById("table-content");

            urls.forEach(url => {
                let new_url = document.createElement('tr');

                let new_url_id = document.createElement('th');
                let new_url_a = document.createElement('a');
                new_url_a.innerText = url.id.S;
                new_url_a.href = config.base_url + "/" + url.id.S
                new_url_a.className = "link-light link-underline-dark"
                new_url_id.appendChild(new_url_a)

                let new_url_url = document.createElement('td');
                new_url_url.innerText = url.url.S

                new_url.appendChild(new_url_id)
                new_url.appendChild(new_url_url)

                table_content.appendChild(new_url)
            });
        })
        .catch((error) => console.error(error));
};


getURLs();
