package uelker.microblog.controller;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import uelker.microblog.dto.CreatePostDto;
import uelker.microblog.dto.ResponsePostDto;
import uelker.microblog.dto.UpdatePostDto;
import uelker.microblog.model.Post;
import uelker.microblog.repository.PostRepository;

@RestController
@RequestMapping("/post-api/v1/posts")
public class PostController {
    private final PostRepository postRepository;

    public PostController(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    @GetMapping("/{id}")
    public ResponsePostDto getPost(@PathVariable("id") String id) {
        System.out.printf("Get post with the id: %s \n", id);
        Post post = postRepository.getPost(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));

        return mapToDto(post);
    }

    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping()
    public ResponsePostDto createPost(@RequestBody @Valid CreatePostDto postDto) {
        System.out.printf("Create a new post: %s \n", postDto);
        Post post = postRepository.createPost(postDto);

        return mapToDto(post);
    }

    @PatchMapping("/{id}")
    public ResponsePostDto updatePost(@PathVariable("id") String id, @RequestBody UpdatePostDto postDto) {
        System.out.printf("Update post %s with the following data: %s \n", id, postDto);
        Post post = postRepository.updatePost(id, postDto);

        return mapToDto(post);
    }

    @ResponseStatus(HttpStatus.NO_CONTENT)
    @DeleteMapping("/{id}")
    public void deletePost(@PathVariable("id") String id) {
        System.out.printf("Delete post with the id: %s \n", id);
        postRepository.deletePost(id);
    }

    private ResponsePostDto mapToDto(Post post) {
        return new ResponsePostDto(
                post.getId(),
                post.getTitle(),
                post.getContent(),
                post.getStatus(),
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}
