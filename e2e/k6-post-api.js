import http from 'k6/http';

export const options = {
    scenarios: {
        posts_scenario: {
            executor: 'ramping-vus',
            stages: [
                {duration: '2m30s', target: 100},
                {duration: '5m', target: 100},
                {duration: '2m30s', target: 0},
            ]
        }
    },
};


export default function () {
    const url = `${__ENV.URL}/microblog-service/post-api/v1/posts`;

    const postId = createUnpublishedPost(url);
    readPost(url, postId);
    publishPost(url, postId);
    removePost(url, postId);
}

function createUnpublishedPost(url) {
    const payload = JSON.stringify({
        title: 'ECS vs. Lambda',
        content: 'In this blog post, we will talk about the pros and cons of Amazon Elastic Container Services (ECS) and AWS Lambda.',
        status: 'IN_PROGRESS'
    });
    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    const response = http.post(url, payload, params);

    return response.json().id;
}

function readPost(url, postId) {
    http.get(`${url}/${postId}`);
}


function publishPost(url, postId) {
    const payload = JSON.stringify({
        status: 'PUBLISHED'
    });
    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };
    http.patch(`${url}/${postId}`, payload, params);
}

function removePost(url, postId) {
    http.del(`${url}/${postId}`);
}
