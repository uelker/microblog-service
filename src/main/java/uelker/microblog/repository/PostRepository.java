package uelker.microblog.repository;

import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import uelker.microblog.dto.CreatePostDto;
import uelker.microblog.dto.UpdatePostDto;
import uelker.microblog.model.Post;

import java.time.LocalDateTime;
import java.util.Optional;

import static java.util.UUID.randomUUID;

@Repository
public class PostRepository {
    private final DynamoDbTable<Post> postTable;

    public PostRepository(DynamoDbTable<Post> postTable) {
        this.postTable = postTable;
    }

    public Post createPost(CreatePostDto postDto) {
        Post post = Post.builder()
                .id(randomUUID().toString())
                .title(postDto.title())
                .content(postDto.content())
                .status(postDto.status())
                .createdAt(LocalDateTime.now())
                .build();

        this.postTable.putItem(post);
        return post;
    }

    public Optional<Post> getPost(String postId) {
        Post post = this.postTable.getItem(Key.builder().partitionValue(postId).build());
        return Optional.ofNullable(post);
    }

    public Post updatePost(String id, UpdatePostDto postDto) {
        Post post = Post.builder()
                .id(id)
                .title(postDto.title())
                .content(postDto.content())
                .status(postDto.status())
                .updatedAt(LocalDateTime.now())
                .build();

        return this.postTable.updateItem(r -> r.item(post).ignoreNulls(Boolean.TRUE));
    }

    public void deletePost(String postId) {
        this.postTable.deleteItem(Key.builder().partitionValue(postId).build());
    }

}
