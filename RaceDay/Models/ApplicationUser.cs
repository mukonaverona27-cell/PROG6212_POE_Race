using System.ComponentModel.DataAnnotations;

namespace RaceDay.Models
{
    public class ApplicationUser : IdentityUser
    {
        [Required]
        [StringLength(50)]
        public string UserName { get; set; }= string.Empty;
        [Required]
        [StringLength(50)]
        public string Password { get; set; }=string.Empty;

        [StringLength(50)]
        public string ? Province{ get; set; }
        public DateTime DateJoined {  get; set; }=DateTime.Now;

    }
}
