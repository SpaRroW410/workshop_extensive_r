<script>
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('img.zoomable').forEach(img => {
      img.addEventListener('click', function () {
        this.classList.toggle('active');
      });
    });
  });
</script>