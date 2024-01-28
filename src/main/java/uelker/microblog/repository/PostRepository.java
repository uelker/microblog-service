package uelker.microblog.repository;

import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import uelker.microblog.model.Post;

@Repository
public class PostRepository {
    private final DynamoDbTable<Post> postTable;

    public PostRepository(DynamoDbTable<Post> postTable) {
        this.postTable = postTable;
    }

    public Post createPost(Post post) {
        this.postTable.putItem(post);
        return post;
    }

    public Post getPost(String postId) {
        return this.postTable.getItem(Key.builder().partitionValue(postId).build());
    }

    public Post updatePost(Post post) {
        return this.postTable.updateItem(r -> r.item(post).ignoreNulls(Boolean.TRUE));
    }

    public void deletePost(String postId) {
        this.postTable.deleteItem(Key.builder().partitionValue(postId).build());
    }

}
